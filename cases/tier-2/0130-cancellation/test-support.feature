@tier-2 @proposal-0130 @capability-testing
Feature: Cancellation in test support
  Checks proposal 0130 (cancelling a journey) with proposal 0108 (Test
  support): the path gains the line `journey cancelled at <step>:
  <checkpoint>`, or `journey cancelled: <checkpoint>` when no step concerns
  it. Scripted runs gain the ending `wait for cancellation`, and a scripted run
  whose journey is cancelled still gives its record, and says that the journey
  was cancelled in place of a result.

  Scenario: The path of a journey cancelled after a step returns
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
      | ship   | success |
    And the instance has the recording reporter of test support
    And the caller cancels the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the path is:
      | line                                                |
      | charge attempt 1 succeeded                          |
      | journey cancelled at charge: after the step returns |
    And the run ended as cancelled

  @proposal-0134
  Scenario: The path of a journey cancelled while waiting names the step waited for
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 1000 ms
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And the instance has the recording reporter of test support
    And the caller cancels the journey on "journey_waiting"
    When the workflow runs
    Then the path is:
      | line                                        |
      | payment attempt 1 pending                   |
      | payment deferred                            |
      | scheduled pass started                      |
      | journey cancelled at payment: while waiting |
    And the run ended as cancelled

  Scenario: The path of a journey cancelled before its first step names no step
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the instance has the recording reporter of test support
    And the caller cancels the journey on "journey_started"
    When the workflow runs
    Then the path is:
      | line                           |
      | journey cancelled: before step |
    And the run ended as cancelled

  @language-checkpoint
  Scenario: A scripted attempt that waits for cancellation, in a scripted run whose journey is cancelled
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the script says:
      | step   | attempt | emits     | emit message | ending                |
      | charge | 1       | step_info | working      | wait for cancellation |
    And the caller cancels the journey on "step_info" of "charge"
    When the workflow runs with the script
    Then the scripted run says the journey was cancelled
    And the scripted run's record of step "charge" holds the attempts 1
    And the last event is "journey_cancelled"
