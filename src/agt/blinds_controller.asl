// blinds controller agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds (was:Blinds)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/blinds.ttl").

// the agent initially believes that the blinds are "lowered"
blinds("lowered").

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:Blinds is located at Url
 * Body: greets the user
*/
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds", Url) <-
    .print("[blinds controller] starting...");
    .my_name(MyName);
    makeArtifact("mqtt_artifact_bc", "room.MQTTArtifact", [MyName], ArtifactId); // Create and associate artifact
    focus(ArtifactId); // Focus on the artifact
    // performs an action that creates a new artifact of type ThingArtifact, named "wristband" using the WoT TD located at Url
    // the action unifies ArtId with the ID of the artifact in the workspace
    makeArtifact("blinds", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], ArtId);
    !raise_blinds
    .

/*
 * Plan to handle observable changes in the artifact
 * Triggered when the "received_message" observable property is added.
 */
@handle_received_message
+received_message(Sender, Performative, Content) : true <-
    println("[Blinds Controller] Message received from ", Sender, " with content: ", Content)
    .
    

/* 
* Plan to raise the blinds.
*/
@raise_blinds_plan
+!raise_blinds : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",["raised"]);
    .print("Blinds raised");
    -+blinds("lowered");
    +blinds("raised")
    .

/* 
* Plan to lower the blinds.
*/
@lower_blinds_plan
+!lower_blinds : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",["lowered"]);
    .print("Blinds lowered");
    -+blinds("raised");
    +blinds("lowered")
    .





/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }