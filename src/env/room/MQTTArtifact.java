package room;
import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import org.eclipse.paho.client.mqttv3.*;

/**
 * A CArtAgO artifact that provides an operation for sending messages to agents 
 * with KQML performatives using the dweet.io API
 */
public class MQTTArtifact extends Artifact {

    MqttClient client;
    String broker = "tcp://test.mosquitto.org:1883";
    String clientId; //HINT: Use different clientIds for different MQTT clients in different MQTTArtifacts.
    String topic = "was-exercise-6/communication-sd";
    int qos = 2;

    /**
     * Initializes the MQTTArtifact by setting the clientId and subscribing
     * to the topic for receiving messages.
     *
     * @param name Unique name for the MQTT client
     */

    public void init(String name){
        //TODO: subscribe to the right topic of the MQTT broker and add observable properties for perceived messages (using a custom MQTTCallack class, and the addMessage internal operation).

        try {
            clientId = name; // Use the provided name for the clientId
            // topic = "was-exercise-6/communication-" + name; // different topic for each agent test
            client = new MqttClient(broker, clientId, null);
            System.out.println("["+ clientId + "] MQTTArtifact created and connected to MQTT broker at: " + broker);


            // Set connection options
            MqttConnectOptions connOpts = new MqttConnectOptions();
            connOpts.setCleanSession(true);

            // Set a custom callback for handling messages
            client.setCallback(new CustomMqttCallback());

            // Connect to the MQTT broker
            client.connect(connOpts);

            // Subscribe to the topic
            client.subscribe(topic, qos);

            // Define observable property to indicate the connection status
            defineObsProperty("connected", true);

        } catch (Exception e) {
            e.printStackTrace();
            failed("Failed to initialize MQTTArtifact: " + e.getMessage());
        }


    }

    /**
     * HINT: Use the syntax sender_agent,performative,content for messages. Performatives different from tell will not be considered in the exercise.
     * Allows agents to send a message in the form "sender_agent,performative,content".
     *
     * @param agent       The name of the agent sending the message
     * @param performative The performative (e.g., tell)
     * @param content     The content of the message
     */


    @OPERATION
    public void sendMsg(String agent, String performative, String content){
        //TODO: complete operation to send messages
        try {
            // Message in the required format
            String message = agent + "," + performative + "," + content;

            // Publish the message to the specified topic
            MqttMessage mqttMessage = new MqttMessage(message.getBytes());
            mqttMessage.setQos(qos);
            client.publish(topic, mqttMessage);
            System.out.println("["+ agent + "] Message sent: " + message);


        } catch (Exception e) {
            e.printStackTrace();
            failed("Failed to send message: " + e.getMessage());
        }

    }

    /**
     * HINT: Create observable properties by calling an internal operation when performing this creation from a callback function.
     * Internal operation to add an observable property when a message is received.
     *
     * @param agent       The sender agent
     * @param performative The performative (should be `tell`)
     * @param content     The message content
     */

    @INTERNAL_OPERATION
    public void addMessage(String agent, String performative, String content) {
        if ("tell".equalsIgnoreCase(performative)) {
            // Define an observable property for the received message
            defineObsProperty("received_message", agent, performative, content);
            //     System.out.println("["+ agent + "] Observable property added: " + agent + ", " + content);
        } else {
            System.out.println("["+ agent + "] Unsupported performative received: " + performative);
        }
    }


    //TODO: create a custom callback class from MQTTCallack to process received messages
    /**
     * HINT: Define a custom MQTTCallback class for processing perceived messages and instantiating new observable properties based on them.
     * Custom MQTT callback class to handle received messages.
     */
    private class CustomMqttCallback implements MqttCallback {
        @Override
        public void connectionLost(Throwable cause) {
            System.err.println("[MQTTArtifact] MQTT connection lost: " + cause.getMessage());

            // Update the observable property for connection status
            try {
                updateObsProperty("connected", false);  // Set connection status to false
            } catch (Exception e) {
                System.err.println("[MQTTArtifact] Failed to update connection status after connection lost.");
            }

            // Attempt to reconnect
            while (!client.isConnected()) {
                try {
                    System.out.println("[MQTTArtifact] Attempting to reconnect...");
                    MqttConnectOptions connOpts = new MqttConnectOptions();
                    connOpts.setCleanSession(true);
                    client.connect(connOpts);

                    // Re-subscribe to the topic after reconnecting
                    client.subscribe(topic, qos);

                    updateObsProperty("connected", true);  // Connection re-established
                    System.out.println("[MQTTArtifact] Reconnected and resumed subscription.");
                } catch (Exception e) {
                    System.err.println("[MQTTArtifact] Reconnection attempt failed: " + e.getMessage());
                    try {
                        Thread.sleep(5000);  // Wait before retrying to reconnect
                    } catch (InterruptedException interrupted) {
                        interrupted.printStackTrace();
                    }
                }
            }
        }



        @Override
        public void messageArrived(String topic, MqttMessage message) {
            try {
                // Parse the received message
                String payload = new String(message.getPayload());
                // System.out.println("[MQTTArtifact] Message received: " + payload);
                String[] parts = payload.split(",", 3); // Split into agent, performative, and content
                if (parts.length == 3) {
                    String agent = parts[0];
                    String performative = parts[1];
                    String content = parts[2];

                    // Trigger the internal operation to add an observable property
                    execInternalOp("addMessage", agent, performative, content);
                } else {
                    System.err.println("[MQTTArtifact] Invalid message format received: " + payload);
                }
            } catch (Exception e) {
                e.printStackTrace();
                failed("Failed to process received message: " + e.getMessage());

            }
        }

        @Override
        public void deliveryComplete(IMqttDeliveryToken token) {
            //     System.out.println("[MQTTArtifact] Message delivery complete.");
        }
    }

}
