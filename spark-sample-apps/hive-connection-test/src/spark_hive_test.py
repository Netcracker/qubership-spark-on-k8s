import sys

from pyspark.sql import SparkSession

import findspark

findspark.init()


# non-tls hive
# spark = SparkSession \
#     .builder.master("local") \
#     .appName("MyApp.com") \
#     .config("spark.sql.warehouse.dir", "s3a://warehouse/hive") \
#     .config("spark.hadoop.hive.metastore.uris", "thrift://10.109.36.230:30441") \
#     .config("spark.hadoop.hive.metastore.schema.verification", "false") \
#     .config("spark.hadoop.hive.metastore.schema.verification.record.version", "false") \
#     .config("spark.hadoop.hive.metastore.use.SSL", "false") \
#     .config('spark.hadoop.fs.s3.buckets.create.enabled', 'true') \
#     .config('spark.hadoop.fs.s3a.endpoint', 'https://test-minio-gateway-nas.qa-kubernetes.openshift.sdntest.netcracker.com') \
#     .config('spark.hadoop.fs.s3a.access.key', 'Z4nz2bxWnWM36lf3K21y') \
#     .config('spark.hadoop.fs.s3a.secret.key', 'oqtAdywaB7c7OJWHQ9rLVuJcKjpUR8iSJfXMPCLr') \
#     .config('spark.hadoop.fs.s3a.connection.ssl.enabled', 'false') \
#     .config('spark.hadoop.fs.s3a.impl', 'org.apache.hadoop.fs.s3a.S3AFileSystem') \
#     .config('spark.hadoop.fs.file.impl', 'com.globalmentor.apache.hadoop.fs.BareLocalFileSystem') \
#     .config('spark.fs.file.impl', 'com.globalmentor.apache.hadoop.fs.BareLocalFileSystem') \
#     .config('spark.hadoop.fs.s3a.path.style.access', 'true') \
#     .config('spark.driver.extraJavaOptions', '-Dcom.amazonaws.sdk.disableCertChecking') \
#     .config('spark.executor.extraJavaOptions', '-Dcom.amazonaws.sdk.disableCertChecking') \
#     .config("spark.hadoop.hive.metastore.truststore.type", "JKS") \
#     .config("spark.hadoop.hive.metastore.truststore.path", "s3a://hive/client.truststore.jks") \
#     .config("spark.hadoop.hive.metastore.truststore.password", "changeit") \
#     .enableHiveSupport() \
#     .getOrCreate()

# tls hive
def main():
    spark = SparkSession \
        .builder.master("local") \
        .appName("MyApp.com") \
        .config("spark.sql.warehouse.dir", "s3a://hive/warehouse") \
        .config("spark.sql.hive.metastore.version", "3.1.3") \
        .config("spark.sql.hive.metastore.jars", "path") \
        .config("spark.sql.hive.metastore.jars.path", "/opt/spark/hivejars/*") \
        .config("spark.hadoop.hive.metastore.uris", "thrift://10.109.36.230:31663") \
        .config("spark.hadoop.hive.metastore.schema.verification", "false") \
        .config("spark.hadoop.hive.metastore.schema.verification.record.version", "false") \
        .config("spark.hadoop.hive.metastore.use.SSL", "false") \
        .config('spark.hadoop.fs.s3.buckets.create.enabled', 'true') \
        .config('spark.hadoop.fs.s3a.endpoint', 'https://test-minio-gateway-nas.qa-kubernetes.openshift.sdntest.netcracker.com') \
        .config('spark.hadoop.fs.s3a.access.key', 'Z4nz2bxWnWM36lf3K21y') \
        .config('spark.hadoop.fs.s3a.secret.key', 'oqtAdywaB7c7OJWHQ9rLVuJcKjpUR8iSJfXMPCLr') \
        .config('spark.hadoop.fs.s3a.connection.ssl.enabled', 'false') \
        .config('spark.hadoop.fs.s3a.impl', 'org.apache.hadoop.fs.s3a.S3AFileSystem') \
        .config('spark.hadoop.fs.s3a.path.style.access', 'true') \
        .config('spark.driver.extraJavaOptions', '-Dcom.amazonaws.sdk.disableCertChecking') \
        .config('spark.executor.extraJavaOptions', '-Dcom.amazonaws.sdk.disableCertChecking') \
        .enableHiveSupport() \
        .getOrCreate()

# from pyspark.shell import sc
# sc.setLogLevel("DEBUG")
# log4j = sc._jvm.org.apache.log4j
# log4j.LogManager.getRootLogger().setLevel(log4j.Level.DEBUG)



#spark.catalog.refreshTable("mysparkdb1.mytable78")

#spark.sql("INSERT INTO mysparkdb1.mytable78 VALUES (1, 'John')")



        
#spark.sql("SELECT * FROM mysparkdb1.mytable78").show()


    spark.sql("SELECT * FROM mysparkdb.mytable7").show()
#spark.sql("show databases").show()
#print(spark.catalog.listDatabases())
    spark.stop()
if __name__ == "__main__":
    main()
