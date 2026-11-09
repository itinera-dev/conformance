@tier-2 @proposal-0135
Feature: The journey timeout
  Checks proposal 0135 (journey and attempt timeouts): a journey timeout on
  the workflow descriptor limits how long a journey may run, measured on the
  executor's clock since `journey_started`, and checked at every executor
  checkpoint of proposal 0130, after cancellation. Once it has passed at a
  checkpoint, the journey fails: `journey_timed_out`, then the step in
  progress given up with the cause `journey timed out` and no outcome hook,
  its after hooks with the endings `timed out` and failed, the pending steps
  abandoned, and the journey's end with `journey_failed` carrying `journey
  timed out`. It never interrupts running code, and once the journey's ending
  is known it changes nothing. The runner's clock moves on by what an attempt
  or a hook is scripted to take, as well as when the executor waits.

  @proposal-0133
  Scenario: A journey timeout found after a step returns gives the step up with no outcome hook
    Given the step policies and their hooks:
      | policy | hook            | requests |
      | tx     | after attempt   | ending   |
      | tx     | after step      | ending   |
      | tx     | on step success |          |
      | tx     | on step failure |          |
    And the workflow policies and their hooks:
      | policy | hook                |
      | audit  | after journey       |
      | audit  | on workflow failure |
    And a workflow "orders" with the policies "audit" and the steps:
      | step   | policies |
      | charge | tx       |
      | ship   |          |
    And the workflow has a journey timeout of 5000 ms
    And step "charge" attempts:
      | attempt | outcome | takes   | contributes        |
      | 1       | success | 6000 ms | {"receipt": "R-1"} |
    And step "ship" succeeds
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | policy | hook                | timeout | checkpoint             | cause             | decided by |
      | step_succeeded    | charge | 1       |        |                     |         |                        |                   |            |
      | journey_timed_out | charge | 1       |        |                     | 5000    | after the step returns |                   |            |
      | hook_called       | charge | 1       | tx     | after attempt       |         |                        |                   |            |
      | step_given_up     | charge | 1       |        |                     |         |                        | journey timed out | default    |
      | hook_called       | charge |         | tx     | after step          |         |                        |                   |            |
      | hook_called       |        |         | audit  | after journey       |         |                        |                   |            |
      | hook_called       |        |         | audit  | on workflow failure |         |                        |                   |            |
      | journey_failed    | charge |         |        |                     |         |                        | journey timed out | default    |
    And the hooks received:
      | policy | hook            | calls | endings   |
      | tx     | after attempt   |       | timed out |
      | tx     | after step      |       | failed    |
      | tx     | on step success | 0     |           |
      | tx     | on step failure | 0     |           |
    And no contribution of "receipt" was committed
    And step "charge" ended as failed after 1 attempts
    And step "ship" ended as not executed after 0 attempts
    And the journey failed
    And the result's failure has the cause "journey timed out"
    And the result's failure carries no reason
    And the result's failure carries no error

  Scenario: A journey timeout found between attempts gives the step up, naming its last attempt
    Given the step policies and their hooks:
      | policy | hook          | takes   |
      | tx     | on step retry | 2000 ms |
    And a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And the workflow has a journey timeout of 5000 ms
    And the workflow lists the reporters "trace"
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        | takes   |
      | 1       | failure | unreachable | 4000 ms |
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | checkpoint     | cause             |
      | step_retrying     | charge | 1       |                |                   |
      | journey_timed_out | charge |         | before attempt |                   |
      | step_given_up     | charge | 1       |                | journey timed out |
      | journey_failed    | charge |         |                | journey timed out |
    And the reporter "trace" received the event "attempt_started" 1 times
    And the reporter "trace" received the event "journey_timed_out" 1 times
    And step "charge" ended as failed after 1 attempts

  @proposal-0134
  Scenario: A journey timeout while waiting for an nbf ends the wait at once and abandons the pending steps
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And the workflow has a journey timeout of 10000 ms
    And the workflow allows pending steps
    And the workflow lists the reporters "trace"
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 60000 ms
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    When the workflow runs
    Then the events include, in order:
      | event             | step    | until                    | checkpoint    | status before | timestamp                |
      | journey_waiting   |         | 2026-01-01T00:00:10.000Z |               |               | 2026-01-01T00:00:00.000Z |
      | journey_timed_out |         |                          | while waiting |               | 2026-01-01T00:00:10.000Z |
      | step_abandoned    | payment |                          |               | Pending       |                          |
      | journey_failed    |         |                          |               |               |                          |
    And the reporter "trace" did not receive the event "step_selected"
    And the reporter "trace" did not receive the event "step_given_up"
    And step "payment" ended as abandoned after 1 attempts
    And the result's failure has the cause "journey timed out"

  Scenario: A journey timeout found while a rescue step runs abandons it and gives up the step it rescues
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow has a journey timeout of 5000 ms
    And the workflow lists the reporters "trace"
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 6000 ms |
    When the workflow runs
    Then the events include, in order:
      | event             | step          | attempt | checkpoint             | cause             |
      | step_succeeded    | charge_rescue | 1       |                        |                   |
      | journey_timed_out | charge        |         | after the step returns |                   |
      | step_given_up     | charge        | 1       |                        | journey timed out |
      | journey_failed    | charge        |         |                        | journey timed out |
    And the reporter "trace" did not receive the event "step_rescued"
    And step "charge_rescue" ended as abandoned after 1 attempts
    And step "charge" ended as failed after 1 attempts

  Scenario: The journey timeout is checked before the attempt timeout
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow has a journey timeout of 5000 ms
    And the workflow lists the reporters "trace"
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 6000 ms |
    When the workflow runs
    Then the reporter "trace" received the event "journey_timed_out" 1 times
    And the reporter "trace" did not receive the event "attempt_timed_out"
    And the result's failure has the cause "journey timed out"

  @proposal-0130
  Scenario: Cancellation is checked before the journey timeout
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow has a journey timeout of 5000 ms
    And the workflow lists the reporters "trace"
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 6000 ms |
    And the caller cancels the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the reporter "trace" did not receive the event "journey_timed_out"
    And the reporter "trace" did not receive the event "attempt_timed_out"
    And the last event is "journey_cancelled"
    And the run ended as cancelled

  @proposal-0133
  Scenario: A journey timeout that passes once after journey has started changes nothing
    Given the workflow policies and their hooks:
      | policy | hook          | takes    |
      | audit  | after journey | 10000 ms |
    And a workflow "orders" with the policies "audit" and the steps:
      | step   |
      | charge |
    And the workflow has a journey timeout of 5000 ms
    And the workflow lists the reporters "trace"
    And step "charge" succeeds
    When the workflow runs
    Then the reporter "trace" did not receive the event "journey_timed_out"
    And the journey succeeded

  Scenario: A journey within its timeout is not affected
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And the workflow has a journey timeout of 5000 ms
    And the workflow lists the reporters "trace"
    And step "charge" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 2000 ms |
    And step "ship" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 2000 ms |
    When the workflow runs
    Then the reporter "trace" did not receive the event "journey_timed_out"
    And the journey succeeded
