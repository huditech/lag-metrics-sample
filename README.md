# Sample for Lag Metrics for Event Hub

This repo sets up a minimal example (using Bicep) for using 
Lag Metrics for Event Hub and defining an Azure Monitor alert.

## Documentation

Documentation regarding Event Hub Lag Metrics can be found [here](https://huditech.github.io/lag-metrics/).

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

Alternatively, you can also run:

```
./deploy.sh
```

This has the advantage that it automatically created the `.env` file for the client (see below)

## Example Client

The `client` folder contain a Javascript client to produce messages
to Event Hub in order to trigger the alert. To use it, either use the `.env` file 
that was auto-created by `./deploy.sh` or create one manually:

```
cd clients
cp .env.template .env
```

Then, run the sender:

```
npm install
node sender.js
```

You can now observe the lag metrics going up after a few minutes and the alerts being fires. 
You can also consume the messages and observe the lag metrics going down again

```
node receiver.js
```
