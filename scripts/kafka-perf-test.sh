#!/bin/bash

function parse_config {
  result=`echo "\n" | cat $1 - | sed -n "/^$2\:/,/^[a-zA-Z0-9]/p" | sed '$d' | sed '1d' | tr -d ' ' | sed '/^#/d' | sed '/^$/d' | sed -e 's/^/-/' | tr '\n' ' ' | tr ':' "$3"`
  if [[ $3 == '=' ]]; then
    result=`echo $result | tr -d '\-'`
  fi
  echo $result
}

function delete_topic {
  echo
  echo "Deleting topic: perf-test-$1"
  kafka-topics \
    --bootstrap-server "$2" \
    --command-config /tmp/kafka.config \
    --delete \
    --if-exists \
    --topic perf-test-$1 > /dev/null 2>&1
  if [ $3 -eq 1 ]; then
    echo
    echo "ERROR: Script aborted!"
    echo
    exit 1
  fi
}

# System Vars
BOOTSTRAT_SERVERS=`cat /tmp/kafka.config | grep bootstrap.servers | awk '{split($0,array,"="); print array[2]}' | tr -d ' '`
TOPIC_PARAMS=`parse_config "/tmp/client.yaml" "topic" " "`
PRODUCER_PROPS=`parse_config "/tmp/client.yaml" "producer-props" "="`
PRODUCER_PARAMS=`parse_config "/tmp/client.yaml" "kafka-producer-perf-test" " "`
CONSUMER_PARAMS=`parse_config "/tmp/client.yaml" "kafka-consumer-perf-test" " "`

echo "Confluent Platform's Performance Test [version "`kafka-topics --version`"]"

echo
echo "Tester ID: $1 ($BOOTSTRAT_SERVERS)"

# Create topic
echo
kafka-topics \
  --bootstrap-server "$BOOTSTRAT_SERVERS" \
  --command-config /tmp/kafka.config \
  --create \
  --topic perf-test-$1 \
  $TOPIC_PARAMS || delete_topic $1 "$BOOTSTRAT_SERVERS" 1

# Start producer
echo
echo "Starting Producer..."
echo " > $PRODUCER_PARAMS"
echo " > $PRODUCER_PROPS"
(kafka-producer-perf-test \
  --topic perf-test-$1 \
  --producer.config /tmp/kafka.config \
  --producer-props $PRODUCER_PROPS \
  $PRODUCER_PARAMS \
  | tee /tmp/producer.dat || delete_topic $1 "$BOOTSTRAT_SERVERS" 1) &
sleep 0.5

# Start consumer(s)
for i in $(seq 1 $2); do
  echo
  echo "Starting Consumer_$i (Consumer Group: perf-test-$1-$i)..."
  echo " > $CONSUMER_PARAMS"
  (kafka-consumer-perf-test \
    --bootstrap-server "$BOOTSTRAT_SERVERS" \
    --consumer.config /tmp/kafka.config \
    --topic perf-test-$1 \
    --group "perf-test-$1-$i" \
    --show-detailed-stats \
    --hide-header \
    $CONSUMER_PARAMS \
    | tee "/tmp/consumer_$i.dat" || delete_topic $1 "$BOOTSTRAT_SERVERS" 1) &
  sleep 0.25
done

# Wait producers and consumer(s) to finish
echo
wait

# Display test results
echo
echo "Test Results:"
tail -n 1 /tmp/producer.dat | sed 's|.(\(.\))|Producer: \1|g'
for i in $(seq 1 $2); do
  echo "Consumer $i:" \
    `cat "/tmp/consumer_$i.dat" \
    | awk -F"," '{if($8>0){msec+=$8};mb=$3}END{print 1000*mb/msec}'`\
    "MB/sec"
done
echo

# Delete topic
delete_topic $1 "$BOOTSTRAT_SERVERS" 0
