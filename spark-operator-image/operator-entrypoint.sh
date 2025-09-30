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
    for filename in ${S3_CERTS_DIR}/*; do
        echo "Importing $filename into Java truststore..."
        ${JAVA_HOME}/bin/keytool -importcert \
          -trustcacerts \
          -keystore ${JAVA_HOME}/lib/security/cacerts \
          -storepass changeit \
          -noprompt \
          -alias "$(basename $filename)" \
          -file "$filename"
    done
fi

exec /usr/bin/tini -s -- /usr/bin/spark-operator "$@"
