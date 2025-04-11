// personal assistant agent

broadcast(mqtt).

/* Initial goals */
// The agent has the goal to start
!start.

/*
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: true (the plan is always applicable)
 * Body: Creates the artifact, initializes it, and sends a test message
 */
+!start : true <-
    .print("[personal assistant] starting...");
    .my_name(MyName);
    makeArtifact("mqtt_artifact_pa", "room.MQTTArtifact", [MyName], ArtifactId); // Create and associate artifact
    focus(ArtifactId); // Focus on the artifact
    !send_message("assistant", "tell", "Hello, this is a test message")
    .
    

/* Plan to send a message using the internal operation defined in the artifact */
+!send_message(Sender, Performative, Content) : true <-
    sendMsg(Sender, Performative, Content)
    .
    

/*
 * Plan to handle observable changes in the artifact
 * Triggered when the "received_message" observable property is added.
 */
@handle_received_message
+received_message(Sender, Performative, Content) : true <-
    println("[Assistant] Message received from ", Sender, " with content: ", Content)
    .
    

/* Plan for selective broadcasting */
@selective_broadcast_plan
+!selective_broadcast(Sender, Performative, Content) : broadcast(mqtt) <-
    !add_message(Sender, Performative, Content).
    

+!selective_broadcast(Sender, Performative, Content) : broadcast(jason) <-
    .broadcast(Performative, message(Sender, Performative, Content));
    println("[Assistant] Broadcasted via Jason: ", Content)
    .
    



/* Import behaviors of agents interacting in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }