const { EventHubConsumerClient, earliestEventPosition  } = require("@azure/event-hubs");
require('dotenv').config()
const { ContainerClient } = require("@azure/storage-blob");    
const { BlobCheckpointStore } = require("@azure/eventhubs-checkpointstore-blob");

const connectionString = process.env.EVENT_HUB_CONNECTION_STRING;
const eventHubName = process.env.EVENT_HUB_NAME
const consumerGroup = "$Default";
const storageConnectionString = process.env.STORAGE_CONNECTION_STRING
const containerName = process.env.OFFSET_CONTAINER_NAME

let consumedEvents = 0;

async function main() {
  // Create a blob container client and a blob checkpoint store using the client.
  const containerClient = new ContainerClient(storageConnectionString, containerName);
  const checkpointStore = new BlobCheckpointStore(containerClient);

  // Create a consumer client for the event hub by specifying the checkpoint store.
  const consumerClient = new EventHubConsumerClient(consumerGroup, connectionString, eventHubName, checkpointStore);

  // Subscribe to the events, and specify handlers for processing the events and errors.
  const subscription = consumerClient.subscribe({
      processEvents: async (events, context) => {
        if (events.length === 0) {
          console.log(`No events received within wait time. Waiting for next interval`);
          return;
        }

        for (const event of events) {
          console.log(`Received event: '${event.body}' from partition: '${context.partitionId}' and consumer group: '${context.consumerGroup}'`);
        }

        consumedEvents += events.length;
        // Update the checkpoint.
        await context.updateCheckpoint(events[events.length - 1]);
      },

      processError: async (err, context) => {
        console.log(`Error : ${err}`);
      }
    },
    { startPosition: earliestEventPosition }
  );

  await new Promise((resolve) => {
    const interval = setInterval(async () => {
      if (consumedEvents > 10) {
        console.log(`More than 10 events were consumed, stopping.`)
        await subscription.close();
        await consumerClient.close();
        resolve();
        clearInterval(interval);
      }
    }, 1000);
  });
}

main().catch((err) => {
  console.log("Error occurred: ", err);
});
