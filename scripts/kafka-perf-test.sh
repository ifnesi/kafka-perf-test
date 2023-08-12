#!/bin/bash

# System Vars
BOOTSTRAT_SERVERS=`cat /tmp/kafka.ini | grep bootstrap.servers | awk '{split($0,array,"="); print array[2]}' | tr -d ' '`
PRODUCER_PROPS=`echo "\n[" | cat /tmp/client.ini - | sed -n '/^\[producer-props\]/,/^\[/p' | sed '$d' | sed '1d' | tr -d ' ' | sed '/^#/d' | tr '\n' ' '`
TOPIC_PARAMS=`echo "\n[" | cat /tmp/client.ini - | sed -n '/^\[topic\]/,/^\[/p' | sed '$d' | sed '1d' | sed '/^#/d' | tr '\n' ' '`
PRODUCER_PARAMS=`echo "\n[" | cat /tmp/client.ini - | sed -n '/^\[kafka-producer-perf-test\]/,/^\[/p' | sed '$d' | sed '1d' | sed '/^#/d' | tr '\n' ' '`
CONSUMER_PARAMS=`echo "\n[" | cat /tmp/client.ini - | sed -n '/^\[kafka-consumer-perf-test\]/,/^\[/p' | sed '$d' | sed '1d' | sed '/^#/d' | tr '\n' ' '`

echo "-----"
echo "Tester ID: $1 ($BOOTSTRAT_SERVERS)"

echo
echo "Creating topic: perf-test-$1"
kafka-topics \
  --bootstrap-server "$BOOTSTRAT_SERVERS" \
  --command-config /tmp/kafka.ini \
  --create \
  --topic perf-test-$1 \
  $TOPIC_PARAMS

echo
echo "Starting Producer"
kafka-producer-perf-test \
  --topic perf-test-$1 \
  --producer.config /tmp/kafka.ini \
  --producer-props $PRODUCER_PROPS \
  $PRODUCER_PARAMS \
  | tee /tmp/producer.dat &

for i in $(seq 1 $2); do
  echo
  echo "Starting Consumer_$i"
  kafka-consumer-perf-test \
    --bootstrap-server "$BOOTSTRAT_SERVERS" \
    --consumer.config /tmp/kafka.ini \
    --topic perf-test-$1 \
    --group "perf-test-$1-$i" \
    --show-detailed-stats \
    --hide-header \
    $CONSUMER_PARAMS \
    | tee "/tmp/consumer_$i.dat" &
done
echo

wait

echo
echo "Deleting topic: perf-test-$1"
kafka-topics \
  --bootstrap-server "$BOOTSTRAT_SERVERS" \
  --command-config /tmp/kafka.ini \
  --delete \
  --if-exists \
  --topic perf-test-$1

echo
echo "Test Results:"
tail -n 1 /tmp/producer.dat | sed 's|.(\(.\))|Producer: \1|g'
for i in $(seq 1 $2); do
  echo "Consumer $i:" \
    `cat "/tmp/consumer_$i.dat" \
    | awk '{ sum += ($5+$10) } END { if (NR > 0) print sum / (2*NR); }'`\
    "MB/sec (Average)"
done
echo

exit
