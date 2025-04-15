// calendar manager agent


// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService (was:CalendarService)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/calendar-service.ttl").


/* Initial beliefs */ 
upcoming_event(_).
/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:CalendarService is located at Url
 * Body: greets the user
*/
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService", Url) <-
    .print("[calendar manager] starting...");
    .my_name(MyName);
    makeArtifact("mqtt_artifact_cm", "room.MQTTArtifact", [MyName], ArtifactId); // Create and associate artifact
    focus(ArtifactId); // Focus on the artifact
    // performs an action that creates a new artifact of type ThingArtifact, named "wristband" using the WoT TD located at Url
    // the action unifies ArtId with the ID of the artifact in the workspace
    makeArtifact("calendar", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], ArtId);
    .wait(4000);
    !read_upcoming_event.

/* 
 * Plan for reacting to the addition of the goal !read_upcoming_event
 * Triggering event: addition of goal !read_upcoming_event
 * Context: true (the plan is always applicable)
 * Body: every 5000ms, the agent exploits the TD Property Affordance of type was:ReadUpcomingEvent to perceive the owner's state
 *       and updates its belief owner_state accordingly
*/
@read_upcoming_event_plan
+!read_upcoming_event : true <-
    -upcoming_event(Old_upcoming_event);
    // performs an action that exploits the TD Property Affordance of type was:ReadUpcomingEvent 
    readProperty("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#ReadUpcomingEvent",  EventList);
    .nth(0,EventList,Event); 
    +upcoming_event(Event);
    
    // // sending messages via mqtt, and only if the state changed
    // // Check if the event has changed and publish only in that case
    // ?upcoming_event(CurrentEvent);
    // !check_different(Event,CurrentEvent,Result);
    // if (Result == true) { 
    //     -+upcoming_event(Event); // Update the stored belief about the event
    //     .print("Upcoming event changed. New event: ", Event);
    //     !send_message("calendar manager", "tell", Event); 
    // } else {
    //     .print("Upcoming event is still: ", Event);
    //     .print("No Event changes to publish");
    // };

    .wait(5000);
    !read_upcoming_event. 

/*
 * Plan for reacting to the addition of the belief !upcoming_event
 * Triggering event: addition of belief !upcoming_event
 * Context: true (the plan is always applicable)
 * Body: announces the current ewvent
*/
@ucoming_event_plan
+upcoming_event(Event) : true <-
    .print("Upcoming event ", Event);
    .send(personal_assistant, tell, upcoming_event(Event))
    .


/* 
 * Plan for reacting to the addition of the belief !old_upcoming_event
 * Triggering event: addition of belief !old_upcoming_event
 * Context: true (the plan is always applicable)
 * Body: announces removes the belief about the old event (untells)
*/
@upcoming_event_remove_plan
-upcoming_event(Event) : true <-
    .print("Upcoming event ", Event," removed via untell");
    .send(personal_assistant, untell, upcoming_event(Event))
    .


/* Plan to send a message using the internal operation defined in the artifact */
@send_message_plan
+!send_message(Sender, Performative, Content) : true <-
    sendMsg(Sender, Performative, Content)
    .

/*
 * Plan for determining whether two events are different
 * Custom operation to check equality of two event strings
 */
@check_different_plan
+!check_different(New, Current, Result) : true <-
    if (New == Current) { // Correctly formatted condition
        Result = false; // Action inside the `if` block
    } else {
        Result = true; // Action inside the `else` block
    }
    .
    







/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }
