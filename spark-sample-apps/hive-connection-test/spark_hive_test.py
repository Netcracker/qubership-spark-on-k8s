import sys
from pyspark.sql import SparkSession
from py4j.java_gateway import java_import

def main():
    spark = SparkSession.builder \
        .appName("Spark-hive-test") \
        .enableHiveSupport() \
        .getOrCreate()

    # Define database and table details
    database_name = "mysparkdb2"
    table_name = "mytable20"
    s3_path = f"s3a://hive/warehouse/{database_name}.db/{table_name}"

    # Get the Hadoop FileSystem
    hadoop_conf = spark._jsc.hadoopConfiguration()
    java_import(spark._jvm, 'org.apache.hadoop.fs.FileSystem')
    java_import(spark._jvm, 'org.apache.hadoop.fs.Path')

    fs = spark._jvm.FileSystem.get(hadoop_conf)

    # Check if S3 path exists before creating the table
    if fs.exists(spark._jvm.Path(s3_path)):
        print(f"❌ S3 path {s3_path} already exists. Skipping table creation.")
    else:
        print(f"✅ S3 path {s3_path} does not exist. Creating table...")

        # Create database and table
        spark.sql(f"CREATE DATABASE IF NOT EXISTS {database_name}")
        spark.sql(f"CREATE TABLE {database_name}.{table_name} (id INT, name STRING)")

        # Sample data
        columns = ["id", "name"]
        data = [(1, "James"), (2, "Ann"), (3, "Jeff"), (4, "Jennifer")]

        sampleDF = spark.createDataFrame(data, schema=columns)
        sampleDF.createOrReplaceTempView("mytemptview")

        # Insert data
        spark.sql(f"INSERT INTO TABLE {database_name}.{table_name} SELECT * FROM mytemptview")

    # Query table if it exists
    try:
        table_exists = spark.sql(f"SHOW TABLES IN {database_name}") \
                            .filter(f"tableName = '{table_name}'") \
                            .count() > 0

        if table_exists:
            print(f"✅ Table {database_name}.{table_name} exists. Fetching data:")
            spark.sql(f"SELECT * FROM {database_name}.{table_name}").show()
        else:
            print(f"❌ Table {database_name}.{table_name} does not exist.")

    except Exception as e:
        print(f"⚠️ Error querying table: {e}")

    spark.stop()

if __name__ == "__main__":
    main()
