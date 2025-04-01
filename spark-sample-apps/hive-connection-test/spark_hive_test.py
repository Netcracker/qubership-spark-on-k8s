import sys
import os
from pyspark.sql import SparkSession

def main():
    aws_access_key = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    ssl_s3_endpoint_url = os.getenv("SSL_S3_ENDPOINT_URL")
    hive_meta_store_thrift_uri = os.getenv("HIVE_METASTORE_THRIFT_URI")

    spark = SparkSession.builder \
        .appName("Spark-hive-test") \
        .config("spark.hadoop.fs.s3a.endpoint", ssl_s3_endpoint_url) \
        .config("spark.hadoop.fs.s3a.access.key", aws_access_key) \
        .config("spark.hadoop.fs.s3a.secret.key", aws_secret_key) \
        .config("spark.hadoop.hive.metastore.uris", hive_meta_store_thrift_uri) \
        .enableHiveSupport() \
        .getOrCreate()
    
    database_name = "mysparkdb2"
    table_name = "mytable20"

# Ensure the database exists before dropping it
    databases = spark.sql("SHOW DATABASES").collect()
    db_names = [db[0] for db in databases]

    if database_name in db_names:
        spark.sql(f"DROP DATABASE IF EXISTS {database_name} CASCADE")
        print(f"Dropped database: {database_name}")
    else:
        print(f"Database {database_name} does not exist.")

# Create the database and table again
    spark.sql(f"CREATE DATABASE IF NOT EXISTS {database_name}")

    spark.sql(f"""
        CREATE TABLE IF NOT EXISTS {database_name}.{table_name} (
            id INT, 
            name STRING
        ) USING PARQUET
        LOCATION 's3a://hive/warehouse/{database_name}.db/{table_name}'
    """)

    columns = ["id", "name"]
    data = [(1, "James"), (2, "Ann"), (3, "Jeff"), (4, "Jennifer")]

    sampleDF = spark.createDataFrame(data, schema=columns)
    sampleDF.createOrReplaceTempView("mytemptview")

# Insert data
    spark.sql(f"INSERT INTO TABLE {database_name}.{table_name} SELECT * FROM mytemptview")
    spark.sql(f"SELECT * FROM {database_name}.{table_name}").show()

    spark.stop()

if __name__ == "__main__":
    main()
