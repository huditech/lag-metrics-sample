#!/bin/bash

export $(cat .env | xargs)

az monitor app-insights query --app $APP_INSIGHTS_APP_ID --analytics-query "customMetrics | where name == 'Event Hub Consumer Lag' | extend eventHub=tostring(customDimensions['Event Hub']) | extend tostring(consumerGroup=customDimensions['Consumer Group']) | extend tostring(partitionId=customDimensions['Partition Id']) | summarize lag=sum(value) by timestamp, eventHub, consumerGroup | order by timestamp desc" --offset 30m
