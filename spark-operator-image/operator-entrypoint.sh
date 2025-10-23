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

if [ -n "${TRUST_CERTS_DIR}" ] && [ "$(ls -A "${TRUST_CERTS_DIR}")" ]; then
    : "${JAVA_WRITABLE_KEYSTORE:?Environment variable JAVA_WRITABLE_KEYSTORE must be set}"

    if [ ! -f "$JAVA_WRITABLE_KEYSTORE" ]; then
        echo "Creating writable Java truststore..."
        cp "${JAVA_HOME}/lib/security/cacerts" "$JAVA_WRITABLE_KEYSTORE"
        chmod 644 "$JAVA_WRITABLE_KEYSTORE"
    fi

    for filename in "${TRUST_CERTS_DIR}"/*; do
        alias_name="$(basename "$filename")"
        echo "Processing certificate: $filename"

        if "${JAVA_HOME}/bin/keytool" -list -keystore "$JAVA_WRITABLE_KEYSTORE" \
            -storepass changeit -alias "$alias_name" > /dev/null 2>&1; then
            echo "Removing existing alias $alias_name..."
            "${JAVA_HOME}/bin/keytool" -delete -alias "$alias_name" \
              -keystore "$JAVA_WRITABLE_KEYSTORE" \
              -storepass changeit || true
        fi

        echo "Importing $alias_name into Java truststore..."
        "${JAVA_HOME}/bin/keytool" -importcert \
          -trustcacerts \
          -keystore "$JAVA_WRITABLE_KEYSTORE" \
          -storepass changeit \
          -noprompt \
          -alias "$alias_name" \
          -file "$filename"
    done
        

    export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=$JAVA_WRITABLE_KEYSTORE -Djavax.net.ssl.trustStorePassword=changeit"
fi

exec /usr/bin/tini -s -- /usr/bin/spark-operator "$@"
