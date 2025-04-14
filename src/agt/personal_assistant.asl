// personal assistant agent

broadcast(mqtt).

/* Task 3.2: Add user preferences for wake-up methods and implement inference rule */
 
!initialize_user_preferences.

+!initialize_user_preferences
    :   true
    <-
        .print("Initializing user preferences for wake-up methods...");

        +ranking(wake_up_method(natural_light), 0);
        +ranking(wake_up_method(artificial_light), 1);
        .print("User preferences initialized.");
    .

/* Inference rule for determining the best wake-up method */
best_option(Option)
    :-  ranking(wake_up_method(Option), Rank)
        & not (ranking(wake_up_method(_), LowerRank) & LowerRank < Rank).



/* Initial beliefs */

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
    .wait(3000);
    .
    

/* Plan to send a message using the internal operation defined in the artifact */
+!send_message(Sender, Performative, Content) : true <-
    sendMsg(Sender, Performative, Content)
    .
    


/*
 * Plan for reacting to the received_message from the calendar manager
 * Triggered when the calendar manager sends the "now" belief.
 */
+received_message("calendar manager", "tell", "now") : received_message("wristband manager", "tell", "awake") <-
    .print("Enjoy your event.")
    .

+received_message("calendar manager", "tell", "now") :
    received_message("wristband manager", "tell", "asleep") <-
    .print("Starting wake-up routine.");
    //!initiate_wake_up_routine
    .


/* Plan to initiate the wake-up routine */
+!initiate_wake_up_routine : true <-
    .print("[personal assistant] Coordinating with blinds and lights controllers...");
   // !start_contract_net_protocol(["blinds_controller", "lights_controller"], "increase_illuminance")
   .




// /* Contract Net Protocol (CNP) Initiator Plan */
// +!start_contract_net_protocol(Agents, Task) : true <-
//     .print("[personal assistant] Sending call for proposals for task: ", Task, " to agents: ", Agents);
//     .broadcast(cfp, Task, Agents); // Broadcast CFP for the task
//     .await(reply(Sender, "propose", ProposalContent), 5000, Replies); // Await proposals for up to 5 seconds
//     !process_proposals(Replies, Task).


// /* Process received proposals */
// +!process_proposals(Replies, Task) :
//     best_option(natural_light)
//     & member(reply(Sender, "propose", wake_up_method(natural_light)), Replies) <-
//     .print("[personal assistant] User prefers natural light. Accepting proposal...");
//     .send(Sender, acceptProposal, Task);
//     !reject_other_proposals(Replies, Sender).

// +!process_proposals(Replies, Task) :
//     best_option(artificial_light)
//     & member(reply(Sender, "propose", wake_up_method(artificial_light)), Replies) <-
//     .print("[personal assistant] User prefers artificial light. Accepting proposal...");
//     .send(Sender, acceptProposal, Task);
//     !reject_other_proposals(Replies, Sender).




// /* Plan to reject all proposals except the accepted one */
// +!reject_other_proposals(Replies, AcceptedSender) : true <-
//     forall(
//         member(reply(Sender, "propose", _), Replies) &
//         Sender \== AcceptedSender,
//         .send(Sender, rejectProposal, "Task not preferred")
//     ).



// /* Handle refuse messages */
// +reply(Sender, "refuse", Content) : true <-
//     .print("[personal assistant] ", Sender, " refused task: ", Content).





/*
 * Plan to handle observable changes in the artifact
 * Triggered when the "received_message" observable property is added.
 */
@handle_received_message
+received_message(Sender, Performative, Content) : true <-
    println("[Assistant] Message received from ", Sender, " with content: ", Content,  " no applicable plan was found")
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