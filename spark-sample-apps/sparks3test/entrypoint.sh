#!/bin/sh
set -ex

# Check that S3_CERTS_DIR is set and not empty
if [ -n "${S3_CERTS_DIR}" ] && [ "$(ls -A "${S3_CERTS_DIR}")" ]; then

    # JAVA_WRITABLE_KEYSTORE must be set
    : "${JAVA_WRITABLE_KEYSTORE:?Environment variable JAVA_WRITABLE_KEYSTORE must be set}"

    # Copy default cacerts if keystore does not exist
    if [ ! -f "$JAVA_WRITABLE_KEYSTORE" ]; then
        cp "${JAVA_HOME}/lib/security/cacerts" "$JAVA_WRITABLE_KEYSTORE"
        chmod 644 "$JAVA_WRITABLE_KEYSTORE"
    fi

    # Import all certificates from S3_CERTS_DIR
    for cert_file in "${S3_CERTS_DIR}"/*; do
        echo "Importing $cert_file into Java truststore..."
        "${JAVA_HOME}/bin/keytool" -importcert \
            -trustcacerts \
            -keystore "$JAVA_WRITABLE_KEYSTORE" \
            -storepass changeit \
            -noprompt \
            -alias "$(basename "$cert_file")" \
            -file "$cert_file"
    done

    # Set JAVA_TOOL_OPTIONS for all Java processes
    export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=$JAVA_WRITABLE_KEYSTORE -Djavax.net.ssl.trustStorePassword=changeit"
fi

