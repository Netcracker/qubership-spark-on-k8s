#!/bin/sh
set -ex

myuid="$(id -u)"
if ! getent passwd "$myuid" >/dev/null 2>&1; then
    for wrapper in /usr/lib/libnss_wrapper.so /usr/libnss_wrapper.so /lib/libnss_wrapper.so /libnss_wrapper.so; do
      if [ -s "$wrapper" ]; then
        NSS_WRAPPER_PASSWD="$(mktemp)"
        NSS_WRAPPER_GROUP="$(mktemp)"
        export LD_PRELOAD="$wrapper" NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
        mygid="$(id -g)"
        printf "spark:x:%s:%s:${SPARK_USER_NAME:-anonymous uid}:%s:/bin/false\n" \
          "$myuid" "$mygid" "$SPARK_HOME" > "$NSS_WRAPPER_PASSWD"
        printf "spark:x:%s:\n" "$mygid" > "$NSS_WRAPPER_GROUP"
        break
      fi
    done
fi

if [ -n "${S3_CERTS_DIR}" ] && [ "$(ls -A "${S3_CERTS_DIR}")" ]; then
    : "${JAVA_WRITABLE_KEYSTORE:?Environment variable JAVA_WRITABLE_KEYSTORE must be set}"

    if [ ! -f "$JAVA_WRITABLE_KEYSTORE" ]; then
        cp "${JAVA_HOME}/lib/security/cacerts" "$JAVA_WRITABLE_KEYSTORE"
        chmod 644 "$JAVA_WRITABLE_KEYSTORE"
    fi

    for filename in "${S3_CERTS_DIR}"/*; do
        echo "Importing $filename into Java truststore..."
        "${JAVA_HOME}/bin/keytool" -importcert \
          -trustcacerts \
          -keystore "$JAVA_WRITABLE_KEYSTORE" \
          -storepass changeit \
          -noprompt \
          -alias "$(basename "$filename")" \
          -file "$filename"
    done

    if [ -n "${TRUST_CERTS_DIR}" ] && [[ "$(ls ${TRUST_CERTS_DIR})" ]]; then

      for filename in "${TRUST_CERTS_DIR}"/*; do
          echo "Import $filename certificate to Java cacerts"
          "${JAVA_HOME}/bin/keytool" -import \
          -trustcacerts \
          -keystore "$JAVA_WRITABLE_KEYSTORE" \
          -storepass changeit \
          -noprompt \
          -alias "$(basename "$filename")" \
          -file "${filename}"
      done;

    fi
        

    export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=$JAVA_WRITABLE_KEYSTORE -Djavax.net.ssl.trustStorePassword=changeit"
fi


if [ -f "$TLS_KEY_PATH" ] && [ -f "$TLS_CERT_PATH" ]; then
  if [ ! -d "$TLS_KEYSTORE_DIR" ]; then
    echo "Creating keystore directory"
    mkdir -p "$TLS_KEYSTORE_DIR"
  fi

  echo "Adding to keystore"
  openssl pkcs12 -export \
    -in "$TLS_CERT_PATH" \
    -inkey "$TLS_KEY_PATH" \
    -out "$TLS_KEYSTORE_DIR/keystore.p12" \
    -passout pass:"$TLS_KEYSTORE_PASSWORD"
fi

exec /usr/bin/tini -s -- /usr/bin/spark-operator "$@"
