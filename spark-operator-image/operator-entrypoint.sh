#!/bin/sh
set -ex

myuid="$(id -u)"
if ! getent passwd "$myuid" >/dev/null 2>&1; then
    for wrapper in {/usr,}/lib{/*,}/libnss_wrapper.so; do
      if [ -s "$wrapper" ]; then
        NSS_WRAPPER_PASSWD="$(mktemp)"
        NSS_WRAPPER_GROUP="$(mktemp)"
        export LD_PRELOAD="$wrapper" NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
        mygid="$(id -g)"
        printf 'spark:x:%s:%s:${SPARK_USER_NAME:-anonymous uid}:%s:/bin/false\n' \
          "$myuid" "$mygid" "$SPARK_HOME" > "$NSS_WRAPPER_PASSWD"
        printf 'spark:x:%s:\n' "$mygid" > "$NSS_WRAPPER_GROUP"
        break
      fi
    done
fi

if [ -n "${S3_CERTS_DIR}" ] && [ "$(ls -A ${S3_CERTS_DIR})" ]; then
    # Ensure writable keystore path is set
    : "${JAVA_WRITABLE_KEYSTORE:?Environment variable JAVA_WRITABLE_KEYSTORE must be set}"

    # Copy base cacerts to writable path if it doesn't exist
    if [ ! -f "$JAVA_WRITABLE_KEYSTORE" ]; then
        cp "${JAVA_HOME}/lib/security/cacerts" "$JAVA_WRITABLE_KEYSTORE"
        chmod 644 "$JAVA_WRITABLE_KEYSTORE"
    fi

    # Import each certificate from the secret
    for filename in "${S3_CERTS_DIR}"/*; do
        echo "Importing $filename into Java truststore..."
        ${JAVA_HOME}/bin/keytool -importcert \
          -trustcacerts \
          -keystore "$JAVA_WRITABLE_KEYSTORE" \
          -storepass changeit \
          -noprompt \
          -alias "$(basename "$filename")" \
          -file "$filename"
    done

    # Make Java use the updated keystore
    export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=$JAVA_WRITABLE_KEYSTORE -Djavax.net.ssl.trustStorePassword=changeit"
fi


exec /usr/bin/tini -s -- /usr/bin/spark-operator "$@"
