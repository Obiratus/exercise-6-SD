# Exercise 6: Interacting Agents on the Web
The git repository can be found here: https://github.com/Obiratus/exercise-6-SD

## Workflow
The assistant tries to wake-up the user according to his preferences. Once the assistant has no more options, it informs Simon's dear friend Philip and thereby outsources the wake-up problem to him.
The wake-up routine is not iterative. The assistant only reacts to the other agents, if there is still an upcoming event and the user asleep.

### Alternative workflow considered
At first I wanted the agents to just publish state changes. This lead to the problem, that agents are dependent on each other, regarding the proper timing of event emitting and network availability.

## Declaration of aids

| Task   | Aid                   | Description                                          |
|--------|-----------------------|------------------------------------------------------|
| Task 1 | IntelliJ AI Assistant | Explain code, Help with syntax. |
| Task 2 | IntelliJ AI Assistant |  Explain code, Help with syntax.|
