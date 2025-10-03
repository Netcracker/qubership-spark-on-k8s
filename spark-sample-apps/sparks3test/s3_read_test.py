from pyspark.sql import SparkSession
import sys

# Create Spark session
spark = SparkSession.builder.appName("S3 JSON Test").getOrCreate()

# Path to JSON file (passed via pyFiles or directly in code)
json_file = "s3a://sparktest/test.JSON"

# Read JSON
df = spark.read.json(json_file)

# Show content
df.show()

# Stop Spark
spark.stop()
