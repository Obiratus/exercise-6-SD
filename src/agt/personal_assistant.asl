// personal assistant agent

broadcast(mqtt).
//broadcast(jason).

/* Add user preferences for wake-up methods and implement inference rule */
 
!initialize_user_preferences.

+!initialize_user_preferences
    :   true
    <-
        .print("Initializing user preferences for wake-up methods...");

        +ranking(wake_up_method("natural_light"), 0);
        +ranking(wake_up_method("artificial_light"), 1);
        .print("User preferences initialized.");
    .

/* Inference rule for determining the best wake-up method */
best_option(Option)
    :-  ranking(wake_up_method(Option), Rank)
        & not (ranking(wake_up_method(_), LowerRank) & LowerRank < Rank).



/* Initial beliefs */
wake_up_ongoing("false").
wake_up_problem_outsourced("false").
wake_up_method(_).


/* Initial goals */
// The agent has the goal to start
!start.

// plan to create received_message events in the desired format.
+!kqml_received(Sender, propose, Content, _MessageId) <-
   .print("Received propose message: translating kqml_received from ", Sender, " with content: ", Content);
   +received_message(Sender, propose, Content).

+!kqml_received(Sender, refuse, Reason, _MessageId) <-
   .print("Received refuse message: translating kqml_received from ", Sender, " with reason: ", Reason);
   +received_message(Sender, refuse, Reason).


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
    

/* Plan to send a message using the internal operation defined in the artifact (via MQTT)*/
+!send_message(Sender, Performative, Content) : true <-
    .print("Sending message using MQTT from ", Sender, " with content: ", Content);
    sendMsg(Sender, Performative, Content)
    .

/*
 * Broadcasting
 * Depending on selected Mode, the agent  sends either via MQTT or Jason’s broadcast.
 */
@selective_broadcast_plan
+!selective_broadcast(Sender, Performative, Content) : broadcast(mqtt) <-
    !send_message(Sender, Performative, Content)
    .

+!selective_broadcast(Sender, Performative, Content) : broadcast(jason) <-
    .broadcast(tell, received_message(Sender, Performative, Content));
    .print("Broadcasting using Jason: ", Content)
    .
    


/*
 * Plan to react to the belief that there is an upcoming event "now"
 * and decides whether to wake the user or let them enjoy the event.
 */
+upcoming_event("now") : true <-
{
    // Query the current owner state belief
    ?owner_state(State);

    // Context check: "awake" vs "asleep"
    if (State == "awake") {
        .print("Enjoy your event.");
    } else {
        if (State == "asleep") {
            .print("Starting wake-up routine...");
            !initiate_wake_up_routine;
        } else {
            .print("Unknown owner state: ", State, ". Unable to determine action.");
        }
    }
}.



/* Plans to initiate the wake-up routine */
+!initiate_wake_up_routine : wake_up_ongoing("false") & wake_up_problem_outsourced("false")
 <-
   -+wake_up_ongoing("true");
   +proposals([]);
   .print("Coordinating with blinds and lights controllers...");
   !selective_broadcast("personal_assistant", "cfp", "increase_illuminance");
   .wait(5000);
   !process_responses;
   -+wake_up_ongoing("false");
   .

+!initiate_wake_up_routine : wake_up_ongoing("true") & wake_up_problem_outsourced("false")
 <-
   -+wake_up_ongoing("true");
   .print("Wake-up routine is already running");
   .

+!initiate_wake_up_routine : wake_up_ongoing("true") & wake_up_problem_outsourced("true")
 <-
   .print("Wake-up problem outsourced to Philip.");
    -received_message(lights_controller,refuse,"light_already_on");
    -received_message(blinds_controller,refuse,"blinds_already_raised");
   .

+!initiate_wake_up_routine : wake_up_ongoing("false") & wake_up_problem_outsourced("true")
 <-
   .print("Wake-up problem outsourced to Philip.");
    -received_message(lights_controller,refuse,"light_already_on");
    -received_message(blinds_controller,refuse,"blinds_already_raised");
   .


/* Plans to handle the proposals and refusals*/
@handle_propose
+received_message(Sender, propose, Content) : proposals(CurrentProposals) <-
    .print("Proposal received from ", Sender, " with content: ", Content);
    // Add the proposal to the list of proposals
    +proposals([proposal(Sender, Content) | CurrentProposals]);
    -proposals(CurrentProposals).

@handle_refuse
+received_message(Sender, refuse, Reason) : true <-
    .print("Refusal received from ", Sender, " with reason: ", Reason)
    .


/* Plans to handle the responses after the cfp time is up*/
@process_responses
+!process_responses : proposals(Proposals) <-
    .print("Processing proposals: ", Proposals);

    if (Proposals == []) {
        // No valid proposals received
        .print("No proposals received! Unable to proceed with wake-up attempts. A dear friend is needed.");
        !send_message("personal_assistant", tell, "Dear Philip, my master Simon needs a proper beat-up to wake up.");
        -+wake_up_problem_outsourced("true");
    

    } else {
        // Dynamically filter proposals matching wake-up methods
        .print("Checking if proposals match user wake-up preferences...");
        +valid_proposals([]); // Initialize valid proposals as an empty list

        // Process each proposal recursively
        !process_proposal_list(Proposals);

        // Retrieve the list of valid proposals
        ?valid_proposals(ValidProposals);
        .print("Valid proposals based on preferences: ", ValidProposals);

        if (ValidProposals == []) {
            .print("No valid wake-up method proposals were found. Unable to proceed.");
        } else {
            // Dynamically build the AvailableRanks list
            +available_ranks([]); 
            !extract_ranks(ValidProposals);

            // Retrieve the built list of AvailableRanks
            ?available_ranks(AvailableRanks);
            .print("Available ranks: ", AvailableRanks);

            // Find the minimum rank
            !find_min(AvailableRanks, MinimumRank);
            .print("Lowest rank is: ", MinimumRank);


            // Find the option corresponding to the minimum rank
            ?ranking(wake_up_method(BestOption), MinimumRank);
            .print("Best available option selected: ", BestOption);
            -+wake_up_method(BestOption);

            // Reject all other valid proposals
            !reject_proposals(ValidProposals, BestOption);

            // Clean up processed beliefs
            .abolish(received_message);
            -wake_up_method(BestOption);
            -received_message(lights_controller,propose,"artificial_light");
            -received_message(blinds_controller,propose,"natural_light");
            -received_message(lights_controller,refuse,"light_already_on");
            -received_message(blinds_controller,refuse,"blinds_already_raised");
            -proposals(Proposals);
            -valid_proposals(ValidProposals); // Remove the temporary belief
            -available_ranks(_); // Clear the ranks list
            
        }
    }.


/* Helper Plans to find the lowest rank, in the valid proposal list*/
@find_min
+!find_min([X], Result) <- 
    Result = X.

+!find_min([X | Rest], Result) <- 
    !find_min(Rest, MinRest); 
    if (X < MinRest) {
        Result = X;
    } else {
        Result = MinRest;
    }.


/* Helper Plans to process the proposal list and generate the valid proposal list*/
@process_proposal_list
+!process_proposal_list([]) <- 
    .print("Finished processing all proposals.").

+!process_proposal_list([proposal(Controller, Option) | Rest]) <-
    // Check if the current proposal's option is a valid wake-up method
    if (ranking(wake_up_method(Option), _)) {
        .print("Valid option found: ", Option, " (from: ", Controller, ")");
        !add_valid_proposal(proposal(Controller, Option)); 
    };
    !process_proposal_list(Rest). 

@add_valid_proposal
+!add_valid_proposal(Proposal) : valid_proposals(CurrentProposals) <-
    -valid_proposals(CurrentProposals);
    +valid_proposals([Proposal | CurrentProposals]).

/* Helper Plans to get the wake up ranks of all elemnts in the valid proposal list*/

@extract_ranks
+!extract_ranks([]) <- // Base case: Empty list
    .print("Finished extracting ranks.").

+!extract_ranks([proposal(_, Option) | Rest]) <-
    if (ranking(wake_up_method(Option), Rank)) {
        !add_rank(Rank); // Add the rank to the `available_ranks` list
    };
    !extract_ranks(Rest). // Process the rest of the list

@add_rank
+!add_rank(Rank) : available_ranks(CurrentRanks) <-
    -available_ranks(CurrentRanks);
    +available_ranks([Rank | CurrentRanks]).



/* Plan to send acceptance messages */
@send_acceptance_plan
+wake_up_method("natural_light"): true <- 
    .print("Sending acceptance to: blinds_controller for natural_light.");
    .send(blinds_controller, achieve, wake_up_method("natural_light"));
    .

+wake_up_method("artificial_light"): true <- 
    .print("Sending acceptance to: lights_controller for artificial_light.");
    .send(lights_controller, achieve, wake_up_method("artificial_light"));
    .

/* Plan to send reject-proposal messages */
@send_reject_plan
+!reject_proposals([], _) <-
    .print("All invalid proposals have been rejected.").

+!reject_proposals([proposal(Sender, Content) | Rest], BestOption) <-
    if (Content \== BestOption) {
        .print("Rejecting proposal from: ", Sender, " with content: ", Content);
        .send(Sender, rejectProposal, Content);
    };
    !reject_proposals(Rest, BestOption).


/*
 * Plan to handle observable changes in the artifact
 * Triggered when the "received_message" observable property is added.
 */
@handle_received_message
+received_message(Sender, Performative, Content) : true <-
    println("[Assistant] Message received from ", Sender, " with content: ", Content,  " no applicable plan was found")
    .
    

/* Import behaviors of agents interacting in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }