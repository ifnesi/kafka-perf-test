# Kafka Performace Tests

Benchmark testing and results for Apache Kafka’s performance, based on:
 - https://developer.confluent.io/learn/kafka-performance
 - https://assets.confluent.io/m/2d7c883a8aa6a71d/original/20200501-WP-Benchmark_Your_Dedicated_Apache_Kafka_Cluster_on_Confluent_Cloud.pdf
 
## Requirements:
- [Docker Desktop + Compose](https://www.docker.com/products/docker-desktop)

## :white_check_mark: Start local Kafka Cluster (Docker)
Run the script `./start-local-kafka.sh` to start docker compose:
 - 3x Zookeeper
 - 3x Confluent Servers
 - 1x Confluent Control Center

## :memo: Run producer/consumer(s) instances (Docker)
Create a configuration file to access the Kafka cluster (`kafka_config_file`). Please refere to the file `./config/kafka-local.config` for the local Kafka cluster (Docker):
```
bootstrap.servers = broker-1:19091,broker-2:19092,broker-3:19093
```

Other configuration file example is `./config/kafka-confluent-cloud.config` (update or create new ones as required).
```
bootstrap.servers = pkc-xxxxxx.eu-central-1.aws.confluent.cloud:9092
security.protocol = SASL_SSL
sasl.mechanism = PLAIN
sasl.jaas.config = org.apache.kafka.common.security.plain.PlainLoginModule required username = "XXXXXX" password = "XXXXXX";
ssl.endpoint.identification.algorithm = https
client.dns.lookup = use_all_dns_ips
```

To start a set of producer and consumer(s), run the script (as many time as needed, but ideally, one set per terminal/container/server/virtual machine): `./run-test-container.sh {kafka_config_file} {client_yaml_file} {number_of_consumers: 3 default}`

A new topic will be created `perf-test-{EPOCH}-{RANDOM}` with the configuration as set on the section `topic:` of the `{client_yaml_file}`.

Producer and consumer(s) based on `kafka-producer-perf-test` and `kafka-consumer-perf-test` respectively (details [here](https://cwiki.apache.org/confluence/display/KAFKA/Performance+testing)).

Where:
 - `kafka_config_file`: File containing the configuration to access the Kafka cluster
 ```
bootstrap.servers = broker-1:19091,broker-2:19092,broker-3:19093
 ```
 - `client_yaml_file`: File containing the configuration for the producer and consumer(s)
 ```
topic:
  - partitions: 108
  - replication-factor: 3

producer-props:
  - acks: all
  - linger.ms: 10
  - compression.type: none

kafka-producer-perf-test:
  - record-size: 512
  - throughput: 60000
  - num-records: 54000000

kafka-consumer-perf-test:
  - messages: 53950000
  - timeout: 30000
 ```
 - `number_of_consumers`: Number of consumers to be started, it must be between `1` and `100` (default is `3`)

If using the local Kafka cluster, then for example run `./run-test-container.sh ./config/kafka-local.config ./config/client-001.yaml 3`. It will connect to the local Kafka cluster and have the 1x producer and 3x consumers configured as per the client YAML file set.

Once the script is completed, it will display the statistics about the specific set of producer/consumer(s) and delete the corresponding topic `perf-test-{EPOCH}-{RANDOM}`:
```
Test Results:
54000000 records sent, 59998.200054 records/sec (29.30 MB/sec), 5.91 ms avg latency, 304.00 ms max latency, 4 ms 50th, 17 ms 95th, 43 ms 99th, 117 ms 99.9th.
Consumer 1: 29.314 MB/sec
Consumer 2: 29.3108 MB/sec
Consumer 3: 29.3074 MB/sec
```

## :x: Stop local Kafka Cluster (Docker)
Run the script `./stop-local-kafka.sh` to stop docker compose.

# External References
Check out [Confluent's Developer portal](https://developer.confluent.io), it has free courses, documents, articles, blogs, podcasts and so many more content to get you up and running with a fully managed Apache Kafka service.

Disclaimer: I work for Confluent :wink: