from pyspark.sql import SparkSession
import os

def main():
    # 1. Read the BUCKET_NAME environment variable
    bucket_name = os.getenv("BUCKET_NAME")
    database_name = os.getenv("DB_NAME")
    if not bucket_name:
        raise ValueError("BUCKET_NAME environment variable not set")

    spark = (
        SparkSession.builder.appName("Spark-hive-test")
        .config("spark.sql.warehouse.dir", f"s3a://{bucket_name}/warehouse/")
        .enableHiveSupport()
        .getOrCreate()
    )

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

    # 2. Use the environment variable to construct the S3 LOCATION path
    table_location = f"s3a://{bucket_name}/warehouse/{database_name}.db/{table_name}"
    print(f"Creating table at location: {table_location}")

    spark.sql(
        f"""
        CREATE TABLE IF NOT EXISTS {database_name}.{table_name} (
            id INT,
            name STRING
        ) USING PARQUET
        LOCATION '{table_location}'
    """
    )

    columns = ["id", "name"]
    data = [(1, "James"), (2, "Ann"), (3, "Jeff"), (4, "Jennifer")]

    sampleDF = spark.createDataFrame(data, schema=columns)
    sampleDF.createOrReplaceTempView("mytemptview")

    # Insert data
    spark.sql(
        f"INSERT INTO TABLE {database_name}.{table_name} SELECT * FROM mytemptview"
    )
    spark.sql(f"SELECT * FROM {database_name}.{table_name}").show()

    spark.stop()

if __name__ == "__main__":
    main()

