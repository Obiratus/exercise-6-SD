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

// plan to create received_message events in the desired format.
+!kqml_received(Sender, rejectProposal, Content, _MessageId) <-
   .print("Received reject-proposal message: translating kqml_received from ", Sender, " with content: ", Content);
   +received_message(Sender, rejectProposal, Content).

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
    .wait(3000);
    //!raise_blinds
    .

@handle_received_message
+received_message(Sender, "cfp", "increase_illuminance") : true <-
    .print("CFP received from: ", Sender, " with content: increase_illuminance");

    if (blinds("lowered")) {
        // If the blinds can open to increase illumination
        .print("Proposing to open the blinds...");
        .send(Sender, propose, "natural_light");

    } else {
        // If the blinds are already raised, refuse the request
        .print("Unable to contribute. Blinds are already raised.");
        .send(Sender, refuse, "blinds_already_raised");
    }
    .

/*
 * Plan to handle the reject proposal messages
 */
@handle_reject_proposal
+received_message(Sender, rejectProposal, Content) : true <-
    .print("Reject proposal received from ", Sender, " with reason: ", Content);
    -received_message(personal_assistant,rejectProposal,"natural_light");
    -received_message("personal_assistant", "cfp", "increase_illuminance")[source(personal_assistant)];
    .



/*
 * Plan to handle observable changes in the artifact
 * Triggered when the "received_message" observable property is added.
 */

+received_message(Sender, Performative, Content) : true <-
    println("Message received from ", Sender, " with content: ", Content)
    .
    


/* 
* Plan to rreact to the added goal wake_up_method("natural_light")
*/
@raise_blinds_goal_plan
+!wake_up_method("natural_light") : true <-
    !raise_blinds;
    .

/* 
* Plan to raise the blinds.
*/
@raise_blinds_plan
+!raise_blinds : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",["raised"]);
    -blinds("lowered");
    +blinds("raised");
    .

/* 
* Plan to lower the blinds.
*/
@lower_blinds_plan
+!lower_blinds : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState",["lowered"]);
    -blinds("raised");
    +blinds("lowered");
    .


/* 
 * Plan for reacting to the addition of the belief !blinds
 * Triggering event: addition of belief !blinds
 * Context: true (the plan is always applicable)
 * Body: announces the current state of the blinds
*/
@blinds_plan
+blinds(State) : true <-
    .print("Blinds: ", State);
    .send(personal_assistant, tell, blinds(State))
    .

/* 
 * Plan for reacting to the removal of the belief !blinds
 * Triggering event: removal of belief !blinds
 * Context: true (the plan is always applicable)
 * Body: removes the old state of the blinds via untell
*/
@blinds_removal_plan
-blinds(State) : true <-
    .print("Blinds state ", State, " removed via untell");
    .send(personal_assistant, untell, blinds(State))
    .





/* Plan to send a message using the internal operation defined in the artifact */
@send_message_plan
+!send_message(Sender, Performative, Content) : true <-
    sendMsg(Sender, Performative, Content)
    .




/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }