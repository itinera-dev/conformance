@tier-2 @proposal-0130
Feature: Cleanup after a cancellation, and when a cancellation counts
  Checks proposal 0130 (cancelling a journey): a cancellation during a wait,
  such as a wait for a pending step's nbf, stops the journey at once, and the
  `Pending` and `Waiting` steps become `Abandoned`, running their `after step`
  hooks with the ending `cancelled`. Cleanup's events are delivered: a failing
  after hook is recorded with `after_hook_failed` and the others still run, and
  a reporter that fails during cleanup receives nothing more while delivery
  goes on to the others; nothing can abort a cancelled journey. A token
  triggered before the journey starts means there is no journey; one triggered
  once the `after journey` hooks have started changes nothing; and an abort
  that comes before the cancellation is honoured stands.

  @proposal-0133 @proposal-0134
  Scenario: A cancellation while waiting stops at once and abandons the pending and waiting steps
    Given the step policies and their hooks:
      | policy | hook       | requests |
      | tx     | after step | ending   |
    And a workflow "orders" with the steps:
      | step    | policies |
      | payment | tx       |
      | receipt | tx       |
    And the workflow allows pending steps
    And the workflow lists the reporters "trace"
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 60000 ms
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    And step "receipt" succeeds
    And the caller cancels the journey on "journey_waiting"
    When the workflow runs
    Then the events include, in order:
      | event             | step    | policy | hook       | checkpoint    | steps            | timestamp                |
      | journey_waiting   | payment |        |            |               |                  |                          |
      | hook_called       | receipt | tx     | after step |               |                  |                          |
      | hook_called       | payment | tx     | after step |               |                  |                          |
      | journey_cancelled |         |        |            | while waiting | payment, receipt | 2026-01-01T00:00:00.000Z |
    And the reporter "trace" did not receive the event "step_selected"
    And the reporter "trace" did not receive the event "step_abandoned"
    And the hook "after step" of policy "tx" received the endings "cancelled", "cancelled"
    And step "payment" ended as abandoned after 1 attempts
    And step "receipt" ended as abandoned after 0 attempts
    And the run ended as cancelled

  @proposal-0133
  Scenario: A failing after hook during cleanup is recorded, the others run, and nothing aborts
    Given the step policies and their hooks:
      | policy | hook          | fails with |
      | tx     | after attempt |            |
      | audit  | after attempt | audit down |
    And a workflow "orders" with the steps:
      | step   | policies  |
      | charge | tx, audit |
    And the workflow lists the reporters "trace"
    And step "charge" succeeds
    And the caller cancels the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | policy | hook          | error      |
      | after_hook_failed | charge | audit  | after attempt | audit down |
      | hook_called       | charge | tx     | after attempt |            |
      | journey_cancelled | charge |        |               |            |
    And the reporter "trace" did not receive the event "journey_aborted"
    And the run ended as cancelled

  @proposal-0133
  Scenario: A reporter that fails during cleanup receives nothing more, and the others receive journey_cancelled
    Given a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" emits journey_info "rolling back"
    And a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And the workflow lists the reporters "trace", "audit"
    And step "charge" succeeds
    And the reporter "audit" throws on "journey_info"
    And the caller cancels the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the reporter "trace" received the event "journey_info"
    And the reporter "trace" received the event "journey_cancelled"
    And the reporter "audit" did not receive the event "journey_cancelled"
    And the reporter "trace" did not receive the event "journey_aborted"
    And the run ended as cancelled

  Scenario: A token triggered before run is called means there is no journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the caller cancelled the journey before it runs
    When the workflow runs
    Then no event was emitted
    And no step ran
    And the run ended as cancelled

  @proposal-0133
  Scenario: A token triggered once after journey has started changes nothing
    Given the workflow policies and their hooks:
      | policy | hook                |
      | audit  | after journey       |
      | audit  | on workflow success |
    And the hook "after journey" of policy "audit" emits journey_info "closing"
    And a workflow "orders" with the policies "audit" and the steps:
      | step   |
      | charge |
    And the workflow lists the reporters "trace"
    And step "charge" succeeds
    And the caller cancels the journey on "journey_info"
    When the workflow runs
    Then the hook "on workflow success" of policy "audit" was called 1 times
    And the reporter "trace" did not receive the event "journey_cancelled"
    And the last event is "journey_succeeded"
    And the journey succeeded

  Scenario: An abort that comes before the cancellation is honoured stands
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow lists the reporters "trace"
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    And the caller cancels the journey on "journey_aborted"
    When the workflow runs
    Then the reporter "trace" did not receive the event "journey_cancelled"
    And the last event is "journey_aborted"
    And the journey was aborted with the abort reason "required data missing"
