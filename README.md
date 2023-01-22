# Sample for Event Hub Lag Metrics

This repo sets up a minimal example (using Bicep) for using 
Event Hub Lag Metrics and defining an Azure Monitor alert.

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
