#!/bin/sh

PATH=/bin:/usr/bin
USER=$(whoami)
SLEEP_DURATION=$(shuf -i 0-3600 -n 1)

/bin/sleep ${SLEEP_DURATION}
RESTART_TIME=$(date +'%d/%b/%Y:%H:%M:%S')
service atom restart

sleep 10

SERVICE_NAME_WORKER_ELAPSED_RUNTIMES=$(ps -ax | grep SERVICE_NAME | awk '{print $1}' | xargs ps -o etime | sed 1d)
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

echo "(${INSTANCE_ID}) - SERVICE_NAME restarted on at ${RESTART_TIME}" >> /var/log/atom-restarts.log
echo "(${INSTANCE_ID}) - Current worker runtimes (in seconds): ${SERVICE_NAME_WORKER_ELAPSED_RUNTIMES}" >> /var/log/SERVICE_NAME-restarts.log