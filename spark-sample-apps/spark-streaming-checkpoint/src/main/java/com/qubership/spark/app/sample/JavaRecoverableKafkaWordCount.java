package com.qubership.spark.app.sample;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Arrays;
import java.util.Map;
import java.util.Set;
import org.apache.log4j.Logger;
import java.util.regex.Pattern;

import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.sql.SparkSession;
import scala.Tuple2;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;

import org.apache.spark.SparkConf;
import org.apache.spark.streaming.api.java.*;
import org.apache.spark.streaming.kafka010.ConsumerStrategies;
import org.apache.spark.streaming.kafka010.KafkaUtils;
import org.apache.spark.streaming.kafka010.LocationStrategies;
import org.apache.spark.streaming.Durations;

/**
 * Consumes messages from one or more topics in Kafka and does wordcount.
 * Usage: JavaDirectKafkaWordCount <brokers> <groupId> <topics>
 *   <brokers> is a list of one or more Kafka brokers
 *   <groupId> is a consumer group name to consume from topics
 *   <topics> is a list of one or more kafka topics to consume from
 *
 * Example:
 *    $ bin/run-example streaming.JavaDirectKafkaWordCount broker1-host:port,broker2-host:port \
 *      consumer-group topic1,topic2
 */

public final class JavaRecoverableKafkaWordCount {
    private static final Pattern SPACE = Pattern.compile(" ");
    private static final Logger logger = Logger.getLogger(JavaRecoverableKafkaWordCount.class);

    public static void main(String[] args) throws Exception {

        SparkSession spark = SparkSession
                .builder()
                .appName("JavaRecoverableKafkaWordCount")
                .getOrCreate();


        logger.debug("spark property BEFORE setting default spark.checkpoint.directory " + spark.sparkContext().getConf().get("spark.checkpoint.directory"));
        String checkpointDirectory = spark.sparkContext().getConf().get("spark.checkpoint.directory", "/mnt/spark/checkpoints");
        logger.debug("spark property AFTER setting default spark.checkpoint.directory " + checkpointDirectory);

        spark.sparkContext().setCheckpointDir(checkpointDirectory);

        JavaSparkContext jsc = new JavaSparkContext(spark.sparkContext());
        JavaStreamingContext jssc = new JavaStreamingContext(jsc, Durations.seconds(2));

        jssc.checkpoint(checkpointDirectory);

        String brokers = jssc.sparkContext().getConf().get("spark.kafka.brokers", "kafka.kafka-service:9092");
        String groupId = jssc.sparkContext().getConf().get("spark.kafka.groupId", "spark-streaming-word-count");
        String topics = jssc.sparkContext().getConf().get("spark.kafka.topics", "spark-streaming-test");
        String securityProtocol = jssc.sparkContext().getConf().get("spark.kafka.securityProtocol", "");
        String saslMechanism = jssc.sparkContext().getConf().get("spark.kafka.saslMechanism", "");
        String saslJaasConfig = jssc.sparkContext().getConf().get("spark.kafka.saslJaasConfig", "");

        Set<String> topicsSet = new HashSet<>(Arrays.asList(topics.split(",")));
        Map<String, Object> kafkaParams = new HashMap<>();
        kafkaParams.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, brokers);
        kafkaParams.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        kafkaParams.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        kafkaParams.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        if (!securityProtocol.isEmpty()) {
            kafkaParams.put("security.protocol", securityProtocol);
        }
        if (!saslMechanism.isEmpty()) {
            kafkaParams.put("sasl.mechanism", saslMechanism);
        }
        if (!saslJaasConfig.isEmpty()) {
            kafkaParams.put("sasl.jaas.config", saslJaasConfig);
        }

        // Create direct kafka stream with brokers and topics
        JavaInputDStream<ConsumerRecord<String, String>> messages = KafkaUtils.createDirectStream(
                jssc,
                LocationStrategies.PreferConsistent(),
                ConsumerStrategies.Subscribe(topicsSet, kafkaParams));

        // Get the lines, split them into words, count the words and print
        JavaDStream<String> lines = messages.map(ConsumerRecord::value);
        JavaDStream<String> words = lines.flatMap(x -> Arrays.asList(SPACE.split(x)).iterator());
        JavaPairDStream<String, Integer> wordCounts = words.mapToPair(s -> new Tuple2<>(s, 1))
                .reduceByKey((i1, i2) -> i1 + i2);
        wordCounts.print();

        // Start the computation
        jssc.start();
        jssc.awaitTermination();
    }
}