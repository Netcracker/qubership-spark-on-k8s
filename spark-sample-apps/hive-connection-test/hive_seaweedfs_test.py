import os
import sys
import time
import logging
import requests
import urllib3
from requests.auth import HTTPBasicAuth
from pyspark.sql import SparkSession

# TLS verification is intentionally disabled for the internal endpoints
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s"
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
            url, data=sql.strip().encode("utf-8"), headers=self.headers, verify=False
        )
        if resp.status_code == 401:
            logger.error(f"Trino Auth Failed: {resp.text}")
        resp.raise_for_status()
        data = resp.json()

        result_rows = []

        # Poll nextUri until complete
        while "nextUri" in data:
            if "data" in data and data["data"]:
                result_rows.extend(data["data"])

            poll_resp = self.session.get(
                data["nextUri"], headers=self.headers, verify=False
            )
            poll_resp.raise_for_status()
            data = poll_resp.json()
            time.sleep(0.2)

        if "data" in data and data["data"]:
            result_rows.extend(data["data"])

        if "error" in data:
            err_msg = data["error"].get("message", "Unknown Trino query error")
            # Trino often wraps the real error (e.g. "Invalid location URI"); include the causes
            causes = []
            info = data["error"].get("failureInfo")
            while info:
                causes.append(f"{info.get('type')}: {info.get('message')}")
                info = info.get("cause")
            if causes:
                err_msg += "\n  Caused by chain:\n    " + "\n    ".join(causes)
            raise RuntimeError(f"Trino execution failed for SQL [{sql}]: {err_msg}")

        return result_rows


def main():
    spark = SparkSession.builder.appName(
        "spark-trino-dynamic-catalog-e2e"
    ).getOrCreate()
    trino_url = os.getenv(
        "TRINO_COORDINATOR_URL", "http://trino-coordinator.trino.svc.cluster.local:8080"
    )
    hive_thrift_url = os.getenv(
        "HIVE_METASTORE_URI", "thrift://hive-metastore.hive.svc.cluster.local:9083"
    )
    # Path of the Hadoop config (defining fs.seaweedfs.impl) inside the Trino pods
    trino_core_site = os.getenv("TRINO_CORE_SITE_PATH", "/etc/trino/core-site.xml")
    warehouse_uri = os.getenv(
        "SEAWEED_WAREHOUSE_URI",
        "seaweedfs://seaweedfs-filer-external.seaweedfs:8888/warehouse",
    ).rstrip("/")

    catalog_name = "seaweed_hive"
    schema_name = "test_schema_s3"
    table_name = "pipeline_events"
    full_table = f"{catalog_name}.{schema_name}.{table_name}"
    schema_location = f"{warehouse_uri}/{schema_name}"

    client = TrinoClient(coordinator_url=trino_url)

    try:
        logger.info(
            "0. Trino nodes answering this test (node_id, uri, version, coordinator):"
        )
        for node in client.execute(
            "SELECT node_id, http_uri, node_version, coordinator FROM system.runtime.nodes"
        ):
            logger.info(f"  {node}")

        logger.info(f"1. Dropping existing catalog '{catalog_name}' if present...")
        client.execute(f"DROP CATALOG IF EXISTS {catalog_name}")

        logger.info(
            f"2. Dynamically creating catalog '{catalog_name}' for SeaweedFS..."
        )
        # seaweedfs:// locations are opened through Trino's Hadoop filesystem support with the
        # SeaweedFS client, which needs the Hadoop config that registers the scheme.
        create_catalog_sql = f"""
        CREATE CATALOG {catalog_name} USING hive
        WITH (
            "hive.metastore.uri" = '{hive_thrift_url}',
            "hive.non-managed-table-writes-enabled" = 'true',
            "fs.hadoop.enabled" = 'true',
            "hive.config.resources" = '{trino_core_site}'
        )
        """
        client.execute(create_catalog_sql)

        logger.info("3. Verifying catalog creation...")
        catalogs = [row[0] for row in client.execute("SHOW CATALOGS")]
        if catalog_name not in catalogs:
            raise AssertionError(
                f"Catalog '{catalog_name}' not found in SHOW CATALOGS output: {catalogs}"
            )
        logger.info(f"Catalog '{catalog_name}' successfully verified in Trino.")

        logger.info(f"4. Creating schema '{schema_name}' at '{schema_location}'...")
        client.execute(
            f"CREATE SCHEMA IF NOT EXISTS {catalog_name}.{schema_name} "
            f"WITH (location = '{schema_location}')"
        )

        logger.info(f"5. Dropping old table '{full_table}' if exists...")
        client.execute(f"DROP TABLE IF EXISTS {full_table}")

        logger.info(f"6. Creating table '{full_table}'...")
        client.execute(
            f"""
            CREATE TABLE {full_table} (
                id BIGINT,
                event_name VARCHAR,
                created_at TIMESTAMP(3)
            )
        """
        )

        logger.info("7. Inserting test records...")
        client.execute(
            f"""
            INSERT INTO {full_table} (id, event_name, created_at)
            VALUES
                (1, 'pipeline_started', current_timestamp),
                (2, 'data_ingested', current_timestamp),
                (3, 'pipeline_completed', current_timestamp)
        """
        )

        logger.info("8. Verifying row count == 3...")
        count_rows = client.execute(f"SELECT COUNT(*) FROM {full_table}")
        actual_count = count_rows[0][0]
        if actual_count != 3:
            raise AssertionError(f"Expected count 3, got: {actual_count}")

        logger.info("9. Verifying row content...")
        table_rows = client.execute(
            f"SELECT id, event_name, created_at FROM {full_table} ORDER BY id"
        )
        logger.info(f"Data in {full_table}:")
        logger.info(f"  {'id':<4} | {'event_name':<20} | created_at")
        for row_id, event_name, created_at in table_rows:
            logger.info(f"  {row_id:<4} | {event_name:<20} | {created_at}")
        data_rows = [row[:2] for row in table_rows]
        expected_rows = [
            [1, "pipeline_started"],
            [2, "data_ingested"],
            [3, "pipeline_completed"],
        ]
        if data_rows != expected_rows:
            raise AssertionError(
                f"Data verification failed! Expected: {expected_rows}, Got: {data_rows}"
            )

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
