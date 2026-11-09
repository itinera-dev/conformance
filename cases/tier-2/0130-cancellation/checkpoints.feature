@tier-2 @proposal-0130 @proposal-0133
Feature: A cancellation honoured at an executor checkpoint
  Checks proposal 0130 (cancelling a journey): when the caller triggers the
  journey's cancellation token after `journey_started`, the journey stops at
  the next checkpoint. What comes after that checkpoint does not run: no
  further step or attempt, outcome hook, rescue, before hook or workflow hook.
  The after hooks of proposal 0133 not yet called run with the ending
  `cancelled`, `journey_cancelled` names the checkpoint and is the last event,
  and `run` ends as the language's cancellation does. The runner cancels in
  reaction to an event: the token is triggered before the recording reporter
  returns from it, so the journey cannot pass its next checkpoint first.

  Scenario: A cancellation after a step returns keeps its outcome fact, and nothing follows from it
    Given the step policies and their hooks:
      | policy | hook            |
      | tx     | after attempt   |
      | tx     | after step      |
      | tx     | on step success |
    And the workflow policies and their hooks:
      | policy | hook                |
      | audit  | after journey       |
      | audit  | on workflow success |
    And the hooks request:
      | policy | hook          | request |
      | tx     | after attempt | ending  |
      | tx     | after step    | ending  |
      | audit  | after journey | ending  |
    And a workflow "orders" with the policies "audit" and the steps:
      | step   | policies | outcome |
      | charge | tx       | success |
      | ship   |          | success |
    And step "charge" contributes "receipt" = "R-1"
    And the caller cancels the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | policy | hook          | checkpoint             |
      | step_succeeded    | charge | 1       |        |               |                        |
      | hook_called       | charge | 1       | tx     | after attempt |                        |
      | hook_called       | charge |         | tx     | after step    |                        |
      | hook_called       |        |         | audit  | after journey |                        |
      | journey_cancelled | charge | 1       |        |               | after the step returns |
    And the last event is "journey_cancelled"
    And the hooks received:
      | policy | hook                | calls | endings   |
      | tx     | after attempt       |       | cancelled |
      | tx     | after step          |       | cancelled |
      | audit  | after journey       |       | cancelled |
      | tx     | on step success     | 0     |           |
      | audit  | on workflow success | 0     |           |
    And no contribution of "receipt" was committed
    And step "charge" ended as abandoned after 1 attempts
    And step "ship" ended as not executed after 0 attempts
    And the run ended as cancelled

  Scenario: After attempt may read what a returned attempt reported when the journey is cancelled
    Given the step policies and their hooks:
      | policy | hook          |
      | tx     | after attempt |
    And the hooks request:
      | policy | hook          | request        | key     | type   | optional |
      | tx     | after attempt | failure reason |         |        | yes      |
      | tx     | after attempt | step data      | receipt | string | yes      |
    And a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" attempts:
      | attempt | outcome | code     | message | details | contributes        |
      | 1       | failure | declined | no      | {}      | {"receipt": "R-1"} |
    And the caller cancels the journey on "step_failed" of "charge"
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received the failure reason with code "declined", message "no" and details {}
    And the hook "after attempt" of policy "tx" received step data "receipt" = "R-1"
    And the run ended as cancelled

  Scenario: A cancellation after a failure retries nothing
    Given a step policy "tx" defines the hook "on step retry"
    And a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And the workflow lists the reporters "trace"
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    And the caller cancels the journey on "step_failed" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | checkpoint             |
      | step_failed       | charge | 1       |                        |
      | journey_cancelled | charge | 1       | after the step returns |
    And the hook "on step retry" of policy "tx" was not called
    And the reporter "trace" did not receive the event "step_retrying"
    And the reporter "trace" received the event "attempt_started" 1 times
    And the run ended as cancelled

  Scenario: A cancellation before a retry's attempt starts no attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow lists the reporters "trace"
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    And the caller cancels the journey on "step_retrying" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | checkpoint     |
      | step_retrying     | charge |                |
      | journey_cancelled | charge | before attempt |
    And the reporter "trace" received the event "attempt_started" 1 times
    And step "charge" ended as abandoned after 1 attempts
    And the run ended as cancelled

  Scenario: A cancellation before a rescue starts no rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" succeeds
    And the caller cancels the journey on "step_rescuing" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | checkpoint    |
      | step_rescuing     | charge |               |
      | journey_cancelled | charge | before rescue |
    And step "charge_rescue" was built 0 times, each time as a new instance
    And the run ended as cancelled

  Scenario: A cancellation before a hook calls neither it nor the hooks after it, and no after step runs twice
    Given the step policies and their hooks:
      | policy | hook            |
      | tx     | after step      |
      | tx     | on step success |
    And a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | tx       | success |
    And step "charge" contributes "receipt" = "R-1"
    And the caller cancels the journey on "contribution_committed" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event                  | step   | policy | hook       | checkpoint  |
      | hook_called            | charge | tx     | after step |             |
      | contribution_committed | charge |        |            |             |
      | journey_cancelled      |        |        |            | before hook |
    And the hooks received:
      | policy | hook            | calls |
      | tx     | after step      | 1     |
      | tx     | on step success | 0     |
    And step "charge" ended as succeeded after 1 attempts
    And the run ended as cancelled

  Scenario: A cancellation before on step failure leaves the step given up, and runs no after step again
    Given the step policies and their hooks:
      | policy | hook            |
      | tx     | after step      |
      | tx     | on step failure |
    And a workflow policy "audit" defines the hook "on workflow failure"
    And a workflow "orders" with the policies "audit" and the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And the caller cancels the journey on "step_given_up" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | policy | hook       | checkpoint  |
      | step_given_up     | charge |        |            |             |
      | hook_called       | charge | tx     | after step |             |
      | journey_cancelled |        |        |            | before hook |
    And the hooks received:
      | policy | hook                | calls |
      | tx     | after step          | 1     |
      | tx     | on step failure     | 0     |
      | audit  | on workflow failure | 0     |
    And step "charge" ended as failed after 1 attempts
    And the run ended as cancelled

  Scenario: A cancellation before a step's turn leaves it not executed, and none of its hooks run
    Given the step policies and their hooks:
      | policy | hook            |
      | done   | on step success |
      | tx     | before step     |
      | tx     | after step      |
    And a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | done     | success |
      | ship   | tx       | success |
    And the caller cancels the journey on "hook_called" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | policy | hook            | checkpoint  |
      | hook_called       | charge | done   | on step success |             |
      | journey_cancelled |        |        |                 | before step |
    And the hooks received:
      | policy | hook        | calls |
      | tx     | before step | 0     |
      | tx     | after step  | 0     |
    And the policy "tx" was built 0 times
    And step "ship" ended as not executed after 0 attempts
    And the run ended as cancelled

  Scenario: A cancellation before building an attempt leaves it with no outcome fact, and runs the after hooks whose instances exist
    Given the step policies and their hooks:
      | policy | hook           |
      | tx     | before attempt |
      | tx     | after attempt  |
      | lock   | before step    |
      | lock   | after step     |
    And the hook "after step" of policy "lock" requests its ending
    And a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | tx, lock | success |
    And the workflow lists the reporters "trace"
    And the caller cancels the journey on "attempt_started" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | policy | hook       | checkpoint      |
      | attempt_started   | charge | 1       |        |            |                 |
      | hook_called       | charge |         | lock   | after step |                 |
      | journey_cancelled | charge | 1       |        |            | before building |
    And the reporter "trace" did not receive the event "step_succeeded"
    And the hooks received:
      | policy | hook           | calls | endings   |
      | tx     | before attempt | 0     |           |
      | tx     | after attempt  | 0     |           |
      | lock   | after step     |       | cancelled |
    And step "charge" was built 0 times, each time as a new instance
    And step "charge" ended as abandoned after 1 attempts
    And the run ended as cancelled

  Scenario: A cancellation while a rescue step runs abandons it, and journey_cancelled names it with the step it rescues
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow lists the reporters "trace"
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" succeeds
    And the caller cancels the journey on "step_succeeded" of "charge_rescue"
    When the workflow runs
    Then the events include, in order:
      | event             | step          | rescue        | checkpoint             |
      | step_succeeded    | charge_rescue |               |                        |
      | journey_cancelled | charge        | charge_rescue | after the step returns |
    And the reporter "trace" did not receive the event "step_rescued"
    And step "charge_rescue" ended as abandoned after 1 attempts
    And the run ended as cancelled
