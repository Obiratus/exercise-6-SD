// lights controller agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights (was:Lights)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/lights.ttl").


/* Initial beliefs */ 
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
    .wait(3000);
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
    .send(personal_assistant, untell, lights(State));
    -lights("off");
    +lights("on");
    //!send_message("lights manager", "tell", "on"); 
    .

/* 
* Plan to switch off the lights.
*/
@turn_light_off_plan
+!turn_light_off : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",["off"]);
    .send(personal_assistant, untell, lights(State));
    -lights("on");
    +lights("off");
    //!send_message("lights manager", "tell", "off"); 
    .

/* 
 * Plan for reacting to the addition of the belief !lights
 * Triggering event: addition of belief !lights
 * Context: true (the plan is always applicable)
 * Body: announces the current state of the light
*/
@lights_plan
+lights(State) : true <-
    .print("Lights turned: ", State);
    .send(personal_assistant, tell, lights(State))
    .

/* 
 * Plan for reacting to the removal of the belief !lights
 * Triggering event: removal of belief !lights
 * Context: true (the plan is always applicable)
 * Body: removes the old state of the light via untell
*/
@lights_removal_plan
-lights(State) : true <-
    .print("Lights state ", State, " removed via untell");
    .send(personal_assistant, untell, lights(State))
    .




/* Plan to send a message using the internal operation defined in the artifact */
@send_message_plan
+!send_message(Sender, Performative, Content) : true <-
    sendMsg(Sender, Performative, Content)
    .




/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }