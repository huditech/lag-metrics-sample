const { EventHubProducerClient } = require("@azure/event-hubs");
require('dotenv').config()

const connectionString = process.env.EVENT_HUB_CONNECTION_STRING;
const eventHubName = process.env.EVENT_HUB_NAME

const NUMBER_OF_EVENTS = 150;

async function main() {

  // Create a producer client to send messages to the event hub.
  const producer = new EventHubProducerClient(connectionString, eventHubName);

  // Prepare a batch of three events.
  const batch = await producer.createBatch();
  for (let i = 0; i < NUMBER_OF_EVENTS; i++) {
    batch.tryAdd({body: `Event ${i}` });
  }

  // Send the batch to the event hub.
  await producer.sendBatch(batch);

  // Close the producer client.
  await producer.close();

  console.log(`A batch of ${NUMBER_OF_EVENTS} events have been sent to the event hub`);
}

main().catch((err) => {
  console.log("Error occurred: ", err);
});
