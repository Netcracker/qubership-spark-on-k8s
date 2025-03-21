import sys
from pyspark.sql import SparkSession

def main():
    spark = SparkSession.builder \
        .appName("Spark-hive-test") \
        .enableHiveSupport() \
        .getOrCreate()

    columns = ["id", "name"]
    data = [(1, "James"), (2, "Ann"), (3, "Jeff"), (4, "Jennifer")]

    sampleDF = spark.createDataFrame(data, schema=columns)
    sampleDF.createOrReplaceTempView("mytemptview")

    spark.sql("CREATE DATABASE IF NOT EXISTS mysparkdb2")
    spark.sql("CREATE TABLE IF NOT EXISTS mysparkdb2.mytable20 (id INT, name STRING)")

    try:
        
        table_exists = spark.sql("SHOW TABLES IN mysparkdb2") \
                            .filter("tableName = 'mytable20'") \
                            .count() > 0

        if table_exists:
            
            row_count = spark.sql("SELECT COUNT(*) FROM mysparkdb2.mytable20").collect()[0][0]

            if row_count == 0:
                print("Table is empty. Inserting data...")
                spark.sql("INSERT INTO mysparkdb2.mytable20 SELECT id, name FROM mytemptview")
            else:
                print("Table already contains data. Skipping insertion.")

            spark.sql("SELECT * FROM mysparkdb2.mytable20").show()
        else:
            print("Table mysparkdb2.mytable20 does not exist.")

    except Exception as e:
        print(f"Error querying table: {e}")
    spark.stop()

if __name__ == "__main__":
    main()
