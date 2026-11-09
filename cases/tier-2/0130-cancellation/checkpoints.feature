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
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    And step "ship" succeeds
    And the step policies define the hooks:
      | policy | hook            | requests   |
      | tx     | after attempt   | the ending |
      | tx     | after step      | the ending |
      | tx     | on step success |            |
    And step "charge" has the policies "tx"
    And the workflow policies define the hooks:
      | policy | hook                | requests   |
      | audit  | after journey       | the ending |
      | audit  | on workflow success |            |
    And the workflow has the policies "audit"
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
    And the hook "after attempt" of policy "tx" received the endings "cancelled"
    And the hook "after step" of policy "tx" received the endings "cancelled"
    And the hook "after journey" of policy "audit" received the endings "cancelled"
    And the hook "on step success" of policy "tx" was not called
    And the hook "on workflow success" of policy "audit" was not called
    And no contribution of "receipt" was committed
    And step "charge" ended as abandoned after 1 attempts
    And step "ship" ended as not executed after 0 attempts
    And the run ended as cancelled

  Scenario: After attempt may read what a returned attempt reported when the journey is cancelled
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     | message | details | contributes        |
      | 1       | failure | declined | no      | {}      | {"receipt": "R-1"} |
    And a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" requests the optional failure reason
    And the hook "after attempt" of policy "tx" requests optional step data "receipt" of type string
    And step "charge" has the policies "tx"
    And the caller cancels the journey on "step_failed" of "charge"
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received the failure reason with code "declined", message "no" and details {}
    And the hook "after attempt" of policy "tx" received step data "receipt" = "R-1"
    And the run ended as cancelled

  Scenario: A cancellation after a failure retries nothing
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    And a step policy "tx" defines the hook "on step retry"
    And step "charge" has the policies "tx"
    And the workflow lists the reporters "trace"
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
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    And the workflow lists the reporters "trace"
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
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    And the step policies define the hooks:
      | policy | hook            |
      | tx     | after step      |
      | tx     | on step success |
    And step "charge" has the policies "tx"
    And the caller cancels the journey on "contribution_committed" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event                  | step   | policy | hook       | checkpoint  |
      | hook_called            | charge | tx     | after step |             |
      | contribution_committed | charge |        |            |             |
      | journey_cancelled      |        |        |            | before hook |
    And the hook "after step" of policy "tx" was called 1 times
    And the hook "on step success" of policy "tx" was not called
    And step "charge" ended as succeeded after 1 attempts
    And the run ended as cancelled

  Scenario: A cancellation before on step failure leaves the step given up, and runs no after step again
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And the step policies define the hooks:
      | policy | hook            |
      | tx     | after step      |
      | tx     | on step failure |
    And step "charge" has the policies "tx"
    And a workflow policy "audit" defines the hook "on workflow failure"
    And the workflow has the policies "audit"
    And the caller cancels the journey on "step_given_up" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | policy | hook       | checkpoint  |
      | step_given_up     | charge |        |            |             |
      | hook_called       | charge | tx     | after step |             |
      | journey_cancelled |        |        |            | before hook |
    And the hook "after step" of policy "tx" was called 1 times
    And the hook "on step failure" of policy "tx" was not called
    And the hook "on workflow failure" of policy "audit" was not called
    And step "charge" ended as failed after 1 attempts
    And the run ended as cancelled

  Scenario: A cancellation before a step's turn leaves it not executed, and none of its hooks run
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And the step policies define the hooks:
      | policy | hook            |
      | done   | on step success |
      | tx     | before step     |
      | tx     | after step      |
    And step "charge" has the policies "done"
    And step "ship" has the policies "tx"
    And the caller cancels the journey on "hook_called" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | policy | hook            | checkpoint  |
      | hook_called       | charge | done   | on step success |             |
      | journey_cancelled |        |        |                 | before step |
    And the hook "before step" of policy "tx" was not called
    And the hook "after step" of policy "tx" was not called
    And the policy "tx" was built 0 times
    And step "ship" ended as not executed after 0 attempts
    And the run ended as cancelled

  Scenario: A cancellation before building an attempt leaves it with no outcome fact, and runs the after hooks whose instances exist
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the step policies define the hooks:
      | policy | hook           | requests   |
      | tx     | before attempt |            |
      | tx     | after attempt  |            |
      | lock   | before step    |            |
      | lock   | after step     | the ending |
    And step "charge" has the policies "tx", "lock"
    And the workflow lists the reporters "trace"
    And the caller cancels the journey on "attempt_started" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | policy | hook       | checkpoint      |
      | attempt_started   | charge | 1       |        |            |                 |
      | hook_called       | charge |         | lock   | after step |                 |
      | journey_cancelled | charge | 1       |        |            | before building |
    And the reporter "trace" did not receive the event "step_succeeded"
    And the hook "before attempt" of policy "tx" was not called
    And the hook "after attempt" of policy "tx" was not called
    And the hook "after step" of policy "lock" received the endings "cancelled"
    And step "charge" was built 0 times, each time as a new instance
    And step "charge" ended as abandoned after 1 attempts
    And the run ended as cancelled

  Scenario: A cancellation while a rescue step runs abandons it, and journey_cancelled names it with the step it rescues
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" succeeds
    And the workflow lists the reporters "trace"
    And the caller cancels the journey on "step_succeeded" of "charge_rescue"
    When the workflow runs
    Then the events include, in order:
      | event             | step          | rescue        | checkpoint             |
      | step_succeeded    | charge_rescue |               |                        |
      | journey_cancelled | charge        | charge_rescue | after the step returns |
    And the reporter "trace" did not receive the event "step_rescued"
    And step "charge_rescue" ended as abandoned after 1 attempts
    And the run ended as cancelled
