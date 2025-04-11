// lights controller agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights (was:Lights)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/lights.ttl").

// The agent initially believes that the lights are "off"
lights("off").

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:Lights is located at Url
 * Body: greets the user
*/
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", Url) <-
    .print("Lights Controller starting...");
    .my_name(MyName);
    makeArtifact("mqtt_artifact_lc", "room.MQTTArtifact", [MyName], ArtifactId); // Create and associate artifact
    focus(ArtifactId); // Focus on the artifact
    makeArtifact("lights", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], ArtId);
    //!turn_light_on
    .

/*
 * Plan to handle observable changes in the artifact
 * Triggered when the "received_message" observable property is added.
 */
@handle_received_message
+received_message(Sender, Performative, Content) : true <-
    println("[Lights Controller] Message received from ", Sender, " with content: ", Content)
    .
    

/* 
* Plan to switch on the lights.
*/
@turn_light_on_plan
+!turn_light_on : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",["on"]);
    .print("Lights turned on");
    -+lights("off");
    +lights("on")
    .

/* 
* Plan to switch off the lights.
*/
@turn_light_off_plan
+!turn_light_off : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",["off"]);
    .print("Lights turned off");
    -+lights("on");
    +lights("off")
    .




/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }