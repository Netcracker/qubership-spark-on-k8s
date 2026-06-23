#!/bin/bash
#
# The file is mostly similar to https://github.com/apache/spark-docker/blob/master/4.1.2/scala2.13-java21-ubuntu/entrypoint.sh
# except logic for modifying certificates is added and history-server entrypoint support is added
#
# Prevent any errors from being silently ignored
set -eo pipefail

echo "[ENTRYPOINT INFO] Starting Spark entrypoint script..."

attempt_setup_fake_passwd_entry() {
  echo "[ENTRYPOINT INFO] Running attempt_setup_fake_passwd_entry()..."
  # Check whether there is a passwd entry for the container UID
  local myuid; myuid="$(id -u)"
  # If there is no passwd entry for the container UID, attempt to fake one
  # You can also refer to the https://github.com/docker-library/official-images/pull/13089#issuecomment-1534706523
  # It's to resolve OpenShift random UID case.
  # See also: https://github.com/docker-library/postgres/pull/448
  if ! getent passwd "$myuid" &> /dev/null; then
      echo "[ENTRYPOINT WARN] No passwd entry found for UID $myuid. Attempting to generate a fake entry..."
      local wrapper
      for wrapper in {/usr,}/lib{/*,}/libnss_wrapper.so; do
        if [ -s "$wrapper" ]; then
          echo "[ENTRYPOINT INFO] Found nss_wrapper at $wrapper. Setting up environment variables..."
          NSS_WRAPPER_PASSWD="$(mktemp)"
          NSS_WRAPPER_GROUP="$(mktemp)"
          export LD_PRELOAD="$wrapper" NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
          local mygid; mygid="$(id -g)"
          printf 'spark:x:%s:%s:${SPARK_USER_NAME:-anonymous uid}:%s:/bin/false\n' "$myuid" "$mygid" "$SPARK_HOME" > "$NSS_WRAPPER_PASSWD"
          printf 'spark:x:%s:\n' "$mygid" > "$NSS_WRAPPER_GROUP"
          break
        fi
      done
  else
      echo "[ENTRYPOINT INFO] Passwd entry already exists for UID $myuid."
  fi
}

create_jceks() {
  echo "[ENTRYPOINT INFO] Running create_jceks()..."

  if [ ! -f /opt/spark/raw-creds/access-key ] || [ ! -f /opt/spark/raw-creds/secret-key ]; then
      echo "[ENTRYPOINT WARN] S3 creds files not found. Skipping JCEKS generation."
      return 0
  fi

  JCEKS_PATH=/opt/spark/secrets/s3.jceks
  echo "[ENTRYPOINT INFO] Creating JCEKS for S3 credentials at ${JCEKS_PATH}..."

  rm -f ${JCEKS_PATH}

  ACCESS=$(cat /opt/spark/raw-creds/access-key)
  SECRET=$(cat /opt/spark/raw-creds/secret-key)

  export HADOOP_CREDSTORE_PASSWORD=$(cat /opt/spark/raw-creds/jceks.pass)

  echo "[ENTRYPOINT INFO] Adding fs.s3a.access.key to JCEKS..."
  /opt/spark/bin/spark-class org.apache.hadoop.security.alias.CredentialShell create fs.s3a.access.key \
      -value "$ACCESS" \
      -provider jceks://file${JCEKS_PATH}

  echo "[ENTRYPOINT INFO] Adding fs.s3a.secret.key to JCEKS..."
  /opt/spark/bin/spark-class org.apache.hadoop.security.alias.CredentialShell create fs.s3a.secret.key \
      -value "$SECRET" \
      -provider jceks://file${JCEKS_PATH}

  chmod 600 ${JCEKS_PATH}

  echo "[ENTRYPOINT INFO] JCEKS created successfully"
}

# QB change: patch certs

if [ -z "$JAVA_HOME" ]; then
    echo "[ENTRYPOINT INFO] JAVA_HOME is not set. Detecting via java settings..."
    JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | awk '{print $3}')
    echo "[ENTRYPOINT INFO] Detected JAVA_HOME: $JAVA_HOME"
fi

if [ -n "${TRUST_CERTS_DIR}" ] && [ -d "${TRUST_CERTS_DIR}" ]; then
    echo "[ENTRYPOINT INFO] TRUST_CERTS_DIR is set and valid: ${TRUST_CERTS_DIR}. Starting certificate patch process..."
    ORIGINAL_CACERTS="${JAVA_HOME}/lib/security/cacerts"
    WRITABLE_CACERTS="/java-security/cacerts"

    echo "Initial Setup: Checking writability of /java-security..."
    
    if [ ! -w "/java-security" ]; then
        echo "ERROR: /java-security is NOT writable. Check your K8s volumeMounts."
    fi

    echo "Refreshing writable cacerts from system..."
    cp -f "$ORIGINAL_CACERTS" "$WRITABLE_CACERTS"
    chmod 664 "$WRITABLE_CACERTS"
    
    for filename in "${TRUST_CERTS_DIR}"/*; do
        if [ -f "$filename" ]; then
            alias_name=$(basename "$filename")
            echo "Importing: $alias_name"
          
            "${JAVA_HOME}/bin/keytool" -import \
                -trustcacerts \
                -alias "$alias_name" \
                -file "${filename}" \
                -keystore "$WRITABLE_CACERTS" \
                -storepass changeit \
                -noprompt \
                -J-Djava.io.tmpdir=/tmp \
                -storetype JKS
        fi
    done;
    
    export SPARK_HISTORY_OPTS="$SPARK_HISTORY_OPTS -Djavax.net.ssl.trustStore=$WRITABLE_CACERTS"
    export SPARK_JAVA_OPT_SSL="-Djavax.net.ssl.trustStore=$WRITABLE_CACERTS"
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS} -Djavax.net.ssl.trustStore=${WRITABLE_CACERTS} -Djavax.net.ssl.trustStorePassword=changeit -Djava.io.tmpdir=/tmp"
    
    echo "Certs successfully patched in writable volume."
else
    echo "[ENTRYPOINT INFO] TRUST_CERTS_DIR is not set or directory doesn't exist. Skipping cert patching."
fi

if [[ -f $TLS_KEY_PATH && -f $TLS_CERT_PATH ]]; then
  echo "[ENTRYPOINT INFO] TLS keys and certs found. Processing keystore..."
  if [ ! -d "${TLS_KEYSTORE_DIR}" ]; then
    echo "Creating keystore directory"
    mkdir -p ${TLS_KEYSTORE_DIR}
  fi
  echo "Adding to keystore"
  openssl pkcs12 -export -in ${TLS_CERT_PATH} -inkey ${TLS_KEY_PATH} -out ${TLS_KEYSTORE_DIR}/keystore.p12 -passout pass:${TLS_KEYSTORE_PASSWORD}
else
  echo "[ENTRYPOINT INFO] TLS key or cert path missing. Skipping keystore creation."
fi

echo "[ENTRYPOINT INFO] Configuring SPARK_CLASSPATH and Java Options..."
SPARK_CLASSPATH="$SPARK_CLASSPATH:${SPARK_HOME}/jars/*"
for v in "${!SPARK_JAVA_OPT_@}"; do
    SPARK_EXECUTOR_JAVA_OPTS+=( "${!v}" )
done

if [ -n "$SPARK_EXTRA_CLASSPATH" ]; then
  echo "[ENTRYPOINT INFO] Appending SPARK_EXTRA_CLASSPATH to SPARK_CLASSPATH..."
  SPARK_CLASSPATH="$SPARK_CLASSPATH:$SPARK_EXTRA_CLASSPATH"
fi

if ! [ -z "${PYSPARK_PYTHON+x}" ]; then
    echo "[ENTRYPOINT INFO] PYSPARK_PYTHON is explicitly set."
    export PYSPARK_PYTHON
fi
if ! [ -z "${PYSPARK_DRIVER_PYTHON+x}" ]; then
    echo "[ENTRYPOINT INFO] PYSPARK_DRIVER_PYTHON is explicitly set."
    export PYSPARK_DRIVER_PYTHON
fi

# If HADOOP_HOME is set and SPARK_DIST_CLASSPATH is not set, set it here so Hadoop jars are available to the executor.
# It does not set SPARK_DIST_CLASSPATH if already set, to avoid overriding customizations of this value from elsewhere e.g. Docker/K8s.
if [ -n "${HADOOP_HOME}"  ] && [ -z "${SPARK_DIST_CLASSPATH}"  ]; then
  echo "[ENTRYPOINT INFO] HADOOP_HOME found and SPARK_DIST_CLASSPATH is empty. Resolving Hadoop classpath..."
  export SPARK_DIST_CLASSPATH="$($HADOOP_HOME/bin/hadoop classpath)"
fi

if ! [ -z "${HADOOP_CONF_DIR+x}" ]; then
  SPARK_CLASSPATH="$HADOOP_CONF_DIR:$SPARK_CLASSPATH";
fi

if ! [ -z "${SPARK_CONF_DIR+x}" ]; then
  SPARK_CLASSPATH="$SPARK_CONF_DIR:$SPARK_CLASSPATH";
elif ! [ -z "${SPARK_HOME+x}" ]; then
  SPARK_CLASSPATH="$SPARK_HOME/conf:$SPARK_CLASSPATH";
fi

# SPARK-43540: add current working directory into executor classpath
SPARK_CLASSPATH="$SPARK_CLASSPATH:$PWD"

# Switch to spark if no USER specified (root by default) otherwise use USER directly
switch_spark_if_root() {
  if [ $(id -u) -eq 0 ]; then
    echo "[ENTRYPOINT INFO] Container running as root. Will switch execution context to user 'spark' via gosu."
    echo gosu spark
  else
    echo "[ENTRYPOINT INFO] Container is not running as root (UID: $(id -u)). Running command natively."
  fi
}

echo "[ENTRYPOINT INFO] Evaluating execution target branch. Argument 1 is: '$1'"

case "$1" in
  driver)
    echo "[ENTRYPOINT INFO] Target branch: driver. Preparing Spark-Submit payload..."
    shift 1
    CMD=(
      "$SPARK_HOME/bin/spark-submit"
      --conf "spark.driver.bindAddress=$SPARK_DRIVER_BIND_ADDRESS"
      --conf "spark.executorEnv.SPARK_DRIVER_POD_IP=$SPARK_DRIVER_BIND_ADDRESS"
      --deploy-mode client
      "$@"
    )
    attempt_setup_fake_passwd_entry
    # Execute the container CMD under tini for better hygiene
    echo "[ENTRYPOINT INFO] Handing off lifecycle control to Tini driver process..."
    exec $(switch_spark_if_root) /usr/bin/tini -s -- "${CMD[@]}"
    ;;
  executor)
    echo "[ENTRYPOINT INFO] Target branch: executor. Preparing KubernetesExecutorBackend payload..."
    shift 1
    CMD=(
      ${JAVA_HOME}/bin/java
      "${SPARK_EXECUTOR_JAVA_OPTS[@]}"
      -Xms"$SPARK_EXECUTOR_MEMORY"
      -Xmx"$SPARK_EXECUTOR_MEMORY"
      -cp "$SPARK_CLASSPATH:$SPARK_DIST_CLASSPATH"
      org.apache.spark.scheduler.cluster.k8s.KubernetesExecutorBackend
      --driver-url "$SPARK_DRIVER_URL"
      --executor-id "$SPARK_EXECUTOR_ID"
      --cores "$SPARK_EXECUTOR_CORES"
      --app-id "$SPARK_APPLICATION_ID"
      --hostname "$SPARK_EXECUTOR_POD_IP"
      --resourceProfileId "$SPARK_RESOURCE_PROFILE_ID"
      --podName "$SPARK_EXECUTOR_POD_NAME"
    )
    attempt_setup_fake_passwd_entry
    # Execute the container CMD under tini for better hygiene
    echo "[ENTRYPOINT INFO] Handing off lifecycle control to Tini executor process..."
    exec $(switch_spark_if_root) /usr/bin/tini -s -- "${CMD[@]}"
    ;;
  # Spark History
  /opt/spark/sbin/start-history-server.sh)
    echo "[ENTRYPOINT INFO] Target branch: start-history-server.sh..."
    attempt_setup_fake_passwd_entry
    create_jceks
    echo "[ENTRYPOINT INFO] Executing History Server entrypoint hook..."
    exec "$@"
    ;;
  *)
    # Non-spark-on-k8s command provided, proceeding in pass-through mode...
    echo "[ENTRYPOINT WARN] Non-spark-on-k8s command provided ('$1'). Proceeding in pass-through mode..."
    exec "$@"
    ;;
esac