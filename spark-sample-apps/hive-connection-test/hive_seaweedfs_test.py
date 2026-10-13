import os
import sys
import time
import logging
import requests
from requests.auth import HTTPBasicAuth
from pyspark.sql import SparkSession

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger("TrinoSparkDynamicCatalogTest")

class TrinoClient:
    """Executes SQL via Trino HTTP REST API directly inside Spark driver."""

    def __init__(self, coordinator_url: str, user: str = "spark", password: str = ""):
        self.coordinator_url = coordinator_url.rstrip("/")
        self.session = requests.Session()
        self.session.verify = False
        if password:
            self.session.auth = HTTPBasicAuth(user, password)
        self.headers = {
            "Content-Type": "text/plain",
            "User-Agent": "Spark-TrinoDynamicCatalogTest/1.0",
            "X-Trino-User": user,
            "X-Trino-Source": "spark-operator",
            "X-Trino-Catalog": "system",
            "X-Trino-Schema": "metadata",
        }

    def execute(self, sql: str):
        url = f"{self.coordinator_url}/v1/statement"
        resp = self.session.post(
            url,
            data=sql.strip().encode("utf-8"),
            headers=self.headers,
            verify=False
        )
        if resp.status_code == 401:
            logger.error(f"Trino Auth Failed: {resp.text}")
        resp.raise_for_status()
        data = resp.json()

        result_rows = []
        columns = []

        # Poll nextUri until complete
        while "nextUri" in data:
            if "data" in data and data["data"]:
                result_rows.extend(data["data"])
            if "columns" in data and data["columns"]:
                columns = data["columns"]

            poll_resp = self.session.get(data["nextUri"], headers=self.headers, verify=False)
            poll_resp.raise_for_status()
            data = poll_resp.json()
            time.sleep(0.2)

        if "data" in data and data["data"]:
            result_rows.extend(data["data"])
        if "columns" in data and data["columns"]:
            columns = data["columns"]

        if "error" in data:
            err_msg = data["error"].get("message", "Unknown Trino query error")
            raise RuntimeError(f"Trino execution failed for SQL [{sql}]: {err_msg}")

        return result_rows


def main():
    # Initialize basic SparkSession
    spark = SparkSession.builder.appName("spark-trino-dynamic-catalog-e2e").getOrCreate()

    # Target service FQDNs across namespaces
    trino_url = os.getenv("TRINO_COORDINATOR_URL", "http://trino-coordinator.trino.svc.cluster.local:8080")
    hive_thrift_url = os.getenv("HIVE_METASTORE_URI", "thrift://hive-metastore.hive.svc.cluster.local:9083")
    seaweedfs_s3_url = os.getenv("SEAWEEDFS_S3_ENDPOINT", "http://seaweedfs-s3.seaweedfs.svc.cluster.local:8333")
    seaweed_key = os.getenv("SEAWEED_ACCESS_KEY", "admin")
    seaweed_secret = os.getenv("SEAWEED_SECRET_KEY", "admin123")

    catalog_name = "seaweed_hive"
    schema_name = "test_schema"
    table_name = "pipeline_events"
    full_table = f"{catalog_name}.{schema_name}.{table_name}"

    client = TrinoClient(coordinator_url=trino_url)

    try:
        logger.info(f"1. Dropping existing catalog '{catalog_name}' if present...")
        client.execute(f"DROP CATALOG IF EXISTS {catalog_name}")

        logger.info(f"2. Dynamically creating catalog '{catalog_name}' for SeaweedFS...")
        create_catalog_sql = f"""
        CREATE CATALOG {catalog_name} USING hive
        WITH (
            "hive.metastore.uri" = '{hive_thrift_url}',
            "hive.s3.endpoint" = '{seaweedfs_s3_url}',
            "hive.s3.aws-access-key" = '{seaweed_key}',
            "hive.s3.aws-secret-key" = '{seaweed_secret}',
            "hive.s3.path-style-access" = 'true',
            "hive.s3.ssl.enabled" = 'false'
        )
        """
        client.execute(create_catalog_sql)

        logger.info("3. Verifying catalog creation...")
        catalogs = [row[0] for row in client.execute("SHOW CATALOGS")]
        if catalog_name not in catalogs:
            raise AssertionError(f"Catalog '{catalog_name}' not found in SHOW CATALOGS output: {catalogs}")
        logger.info(f"Catalog '{catalog_name}' successfully verified in Trino.")

        logger.info(f"4. Creating schema '{schema_name}'...")
        client.execute(f"CREATE SCHEMA IF NOT EXISTS {catalog_name}.{schema_name}")

        logger.info(f"5. Dropping old table '{full_table}' if exists...")
        client.execute(f"DROP TABLE IF EXISTS {full_table}")

        logger.info(f"6. Creating table '{full_table}'...")
        client.execute(f"""
            CREATE TABLE {full_table} (
                id BIGINT,
                event_name VARCHAR,
                created_at TIMESTAMP(6)
            )
        """)

        logger.info("7. Inserting test records...")
        client.execute(f"""
            INSERT INTO {full_table} (id, event_name, created_at)
            VALUES
                (1, 'pipeline_started', current_timestamp),
                (2, 'data_ingested', current_timestamp),
                (3, 'pipeline_completed', current_timestamp)
        """)

        logger.info("8. Verifying row count == 3...")
        count_rows = client.execute(f"SELECT COUNT(*) FROM {full_table}")
        actual_count = count_rows[0][0]
        if actual_count != 3:
            raise AssertionError(f"Expected count 3, got: {actual_count}")

        logger.info("9. Verifying row content...")
        data_rows = client.execute(f"SELECT id, event_name FROM {full_table} ORDER BY id")
        expected_rows = [
            [1, "pipeline_started"],
            [2, "data_ingested"],
            [3, "pipeline_completed"]
        ]
        if data_rows != expected_rows:
            raise AssertionError(f"Data verification failed! Expected: {expected_rows}, Got: {data_rows}")

        logger.info("All dynamic catalog assertions passed successfully!")

    except Exception as e:
        logger.error(f"E2E test failed: {e}", exc_info=True)
        sys.exit(1)

    finally:
        logger.info("10. Cleanup: dropping table, schema, and catalog...")
        try:
            client.execute(f"DROP TABLE IF EXISTS {full_table}")
            client.execute(f"DROP SCHEMA IF EXISTS {catalog_name}.{schema_name}")
            client.execute(f"DROP CATALOG IF EXISTS {catalog_name}")
            logger.info("Cleanup completed.")
        except Exception as cleanup_err:
            logger.warning(f"Cleanup warning: {cleanup_err}")

        spark.stop()


if __name__ == "__main__":
    main()