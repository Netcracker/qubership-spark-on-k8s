import sys
from pyspark.sql import SparkSession
import delete_s3


def main():
    aws_access_key = delete_s3.get_secret("AWS_ACCESS_KEY_ID")
    aws_secret_key = delete_s3.get_secret("AWS_SECRET_ACCESS_KEY")
    s3_endpoint_url = delete_s3.get_secret("S3_ENDPOINT_URL")
    bucket_name = delete_s3.get_secret("BUCKET_NAME")
    table_name = delete_s3.get_secret("TABLE_NAME")
    database_name = delete_s3.get_secret("DB_NAME")
    # Initialize Spark Session
    spark = (
        SparkSession.builder.appName("Spark-hive-test")
        .config("spark.hadoop.fs.s3a.access.key", aws_access_key)
        .config("spark.hadoop.fs.s3a.secret.key", aws_secret_key)
        .config("spark.hadoop.fs.s3a.endpoint", s3_endpoint_url)
        .enableHiveSupport()
        .getOrCreate()
    )
    spark.sparkContext.setLogLevel("ERROR")

    log4jLogger = spark._jvm.org.apache.log4j
    log4jLogger.LogManager.getLogger("org.apache.spark").setLevel(
        log4jLogger.Level.ERROR
    )
    log4jLogger.LogManager.getLogger("org.apache.hadoop").setLevel(
        log4jLogger.Level.ERROR
    )
    log4jLogger.LogManager.getLogger("hive").setLevel(log4jLogger.Level.ERROR)

    table_location = f"s3a://{bucket_name}/warehouse/{database_name}.db/{table_name}"

    print(f"\n[STARTING JOB]: {database_name}.{table_name}")

    exit_code = 0
    try:

        sc = spark.sparkContext
        Path = sc._gateway.jvm.org.apache.hadoop.fs.Path
        FileSystem = sc._gateway.jvm.org.apache.hadoop.fs.FileSystem
        hadoop_conf = sc._jsc.hadoopConfiguration()
        hadoop_conf.set("fs.s3a.endpoint", s3_endpoint_url)
        hadoop_conf.set("fs.s3a.path.style.access", "true")
        fs = FileSystem.get(Path(table_location).toUri(), hadoop_conf)

        if not fs.exists(Path(table_location)):
            fs.mkdirs(Path(table_location))

        spark.sql(f"CREATE DATABASE IF NOT EXISTS {database_name}")

        spark.sql(
            f"""
            CREATE TABLE IF NOT EXISTS {database_name}.{table_name} (
                id INT,
                name STRING
            )
            USING PARQUET
            LOCATION '{table_location}'
        """
        )

        # 2. Insert Data
        spark.sql(
            f"INSERT INTO {database_name}.{table_name} VALUES (1, 'James'), (2, 'Ann')"
        )

        # 3. VERIFICATION LOGIC
        results_df = spark.sql(f"SELECT * FROM {database_name}.{table_name}")
        row_count = results_df.count()

        print("\n--- Final Result ---")
        results_df.show()

        if row_count == 0:
            print(f"\n[VALIDATION FAILURE]: Expected rows, but found {row_count}")
            exit_code = 1

    except Exception as e:
        print(f"\n[FATAL ERROR]: {str(e)}")
        exit_code = 1
    finally:
        spark.stop()
        print("[JOB COMPLETED]")
        if exit_code != 0:
            sys.exit(exit_code)


if __name__ == "__main__":
    main()
