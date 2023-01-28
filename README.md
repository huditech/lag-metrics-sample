# Sample for Event Hub Lag Metrics

This repo sets up a minimal example (using Bicep) for using 
Event Hub Lag Metrics and defining an Azure Monitor alert.

## Documentation

Documentation regarding Event Hub Lag Metrics can be found [here](https://huditech.github.io/event-hub-lag-metrics/).

## Deploy the sample

You must create the resource group beforehand, e.g. with:

```
az group create \
  --name lag-monitor-test \
  --location EastUS \
  --subscription YOUR_SUBSCRIPTION_NAME_OR_ID
```

The sample can then be deployed with:

```
az deployment group create \
    --resource-group lag-monitor-test \
    --subscription YOUR_SUBSCRIPTION_NAME_OR_ID \
    -f main.bicep
```

## Example Client

The `client` folder contain a Javascript client to produce messages
to Event Hub in order to trigger the alert. To use it:

```
cd clients
cp .env.template .env
```

Fill out the file `.env` with the connection strings of the Event Hub Namespace and the 
Storage Account.

```
npm install
node sender.js
```
