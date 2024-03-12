#!/bin/bash

# Log file path
LOG_FILE="/var/log/SERVICE_NAME.log"

# Check if the service is running
if ! systemctl is-active --quiet SERVICE_NAME; then
    # Attempt to start the Atom service
    systemctl start SERVICE_NAME > /dev/null 2>&1

    # Check if the service started successfully
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        echo "$(date): SERVICE_NAME service was found to be in a stopped state. Systemctl started the service successfully." >> "$LOG_FILE"
    else
        echo "$(date): Failed to start SERVICE_NAME service." >> "$LOG_FILE"
        exit $EXIT_CODE
    fi
fi