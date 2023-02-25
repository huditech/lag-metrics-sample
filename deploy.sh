#!/bin/bash

set -e

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "Usage: ./deploy.sh you@example.com"
    exit 1
fi

EMAIL=$1

az group create \
  --name lag-monitor-sample \
  --location WestEurope

az deployment group create \
    --resource-group lag-monitor-sample \
    --parameters notificationEmailAddress="$EMAIL" \
    -f main.bicep | tee output.json

EVENT_HUB_CONNECTION_STRING=$(jq < output.json '.properties.outputs.eventHubConnectionString.value' -r)
STORAGE_CONNECTION_STRING=$(jq < output.json '.properties.outputs.storageConnectionString.value' -r)
OFFSET_CONTAINER_NAME=$(jq < output.json '.properties.outputs.offsetContainerName.value' -r)
EVENT_HUB_NAME=$(jq < output.json '.properties.outputs.eventHubName.value' -r)
APP_INSIGHTS_APP_ID=$(jq < output.json '.properties.outputs.appInsightsAppId.value' -r)

echo "Storing secrets in clients/.env"
echo "EVENT_HUB_CONNECTION_STRING=$EVENT_HUB_CONNECTION_STRING" > clients/.env
echo "STORAGE_CONNECTION_STRING=$STORAGE_CONNECTION_STRING" >> clients/.env
echo "OFFSET_CONTAINER_NAME=$OFFSET_CONTAINER_NAME" >> clients/.env
echo "EVENT_HUB_NAME=$EVENT_HUB_NAME" >> clients/.env
echo "APP_INSIGHTS_APP_ID=$APP_INSIGHTS_APP_ID" >> clients/.env

