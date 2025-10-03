from pyspark.sql import SparkSession
import sys
import os

# Create Spark session
spark = SparkSession.builder.appName("S3 connection Test").getOrCreate()
s3_file = os.getenv("S3_JSON_FILE")

# Path to JSON file (passed via pyFiles or directly in code)
json_file = s3_file

# Read JSON
df = spark.read.json(json_file)

# Show content
df.show()

# Stop Spark
spark.stop()
