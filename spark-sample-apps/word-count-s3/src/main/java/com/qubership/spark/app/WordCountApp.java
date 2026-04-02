package com.qubership.spark.app;

import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.sql.SparkSession;
import org.apache.hadoop.conf.Configuration;
import scala.Tuple2;
import java.nio.file.Files;
import java.nio.file.Paths;

import java.util.Arrays;

public final class WordCountApp {
    public static void main(String[] args) throws Exception {

        SparkSession spark = SparkSession
                .builder()
                .appName("JavaWordCount")
                .getOrCreate();

	setupS3Credentials(spark);		

        JavaSparkContext jsc = new JavaSparkContext(spark.sparkContext());
        
        JavaRDD<String> textFile = jsc.textFile(jsc.getConf().get("spark.s3.input.file"));
        JavaPairRDD<String, Integer> counts = textFile
                .flatMap(s -> Arrays.asList(s.split(" ")).iterator())
                .mapToPair(word -> new Tuple2<>(word, 1))
                .reduceByKey((a, b) -> a + b);
        counts.saveAsTextFile(jsc.getConf().get("spark.s3.output.path"));

        spark.stop();
    }
    public static void setupS3Credentials(SparkSession spark) throws Exception {
        Configuration hadoopConf = spark.sparkContext().hadoopConfiguration();

        String accessKey = new String(
            Files.readAllBytes(Paths.get("/opt/spark/raw-creds/accesskey"))
        ).trim();

        String secretKey = new String(
            Files.readAllBytes(Paths.get("/opt/spark/raw-creds/secretkey"))
        ).trim();

        hadoopConf.set("fs.s3a.access.key", accessKey);
        hadoopConf.set("fs.s3a.secret.key", secretKey);

        System.out.println("S3 credentials set programmatically");
   }
    
}