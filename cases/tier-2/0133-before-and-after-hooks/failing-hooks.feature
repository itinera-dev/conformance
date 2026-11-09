@tier-2 @proposal-0133
Feature: Before and after hooks that fail
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): a failing before or after hook is recorded by `before_hook_failed`
  or `after_hook_failed`. A failing `before step` gives the step up with no
  attempt and the cause `before hook failed`. A failing `before attempt` is the
  attempt's outcome fact, and the attempt goes the abnormal termination path
  with that cause. A failing `after attempt` or `after step` after a success
  goes the abnormal termination path, or gives the step up, with the cause
  `after hook failed`, and the contributions are not committed. A failing
  `after journey` after a success fails the journey. After any other ending, a
  failing after hook is recorded and changes nothing. The other after hooks of
  the level still run, and the first failure's error is the one carried.

  Scenario: A failing before step gives the step up with no attempt, and on step failure is not called
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | lock     |
      | ship   |          |
    And step "charge" succeeds
    And step "ship" succeeds
    And its step policies and their hooks are:
      | policy | hook            | fails with |
      | lock   | before step     | no lock    |
      | lock   | after step      |            |
      | lock   | on step failure |            |
    When the workflow runs
    Then the events include, in order:
      | event              | step   | policy | hook        | cause              | error   |
      | before_hook_failed | charge | lock   | before step |                    | no lock |
      | step_given_up      | charge |        |             | before hook failed |         |
      | hook_called        | charge | lock   | after step  |                    |         |
      | journey_failed     | charge |        |             | before hook failed |         |
    And the hook "on step failure" of policy "lock" was not called
    And step "charge" was built 0 times, each time as a new instance
    And step "charge" ended as failed after 0 attempts
    And step "ship" ended as not executed after 0 attempts
    And the journey failed
    And the result's failure has the cause "before hook failed"
    And the result's failure carries no reason
    And the result's failure carries the error "no lock"

  Scenario: A failing before attempt is the attempt's outcome fact, and the attempt goes the abnormal termination path
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx, lock |
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook                         | fails with    |
      | tx     | before attempt               | no connection |
      | tx     | after attempt                |               |
      | tx     | on step abnormal termination |               |
      | tx     | on step failure              |               |
      | lock   | before attempt               |               |
      | lock   | after attempt                |               |
    When the workflow runs
    Then the events include, in order:
      | event              | step   | attempt | policy | hook                         | cause              | error         |
      | attempt_started    | charge | 1       |        |                              |                    |               |
      | before_hook_failed | charge | 1       | tx     | before attempt               |                    | no connection |
      | hook_called        | charge | 1       | tx     | after attempt                |                    |               |
      | hook_called        | charge | 1       | tx     | on step abnormal termination |                    |               |
      | step_given_up      | charge | 1       |        |                              | before hook failed |               |
      | hook_called        | charge | 1       | tx     | on step failure              |                    |               |
      | journey_failed     | charge |         |        |                              | before hook failed |               |
    And the hooks were called in this order:
      | policy | hook                         |
      | tx     | before attempt               |
      | tx     | after attempt                |
      | tx     | on step abnormal termination |
      | tx     | on step failure              |
    And step "charge" was built 0 times, each time as a new instance
    And step "charge" ended as failed after 1 attempts
    And the result's failure has the cause "before hook failed"
    And the result's failure carries the error "no connection"

  Scenario: A failing before attempt is retried while the retry budget lasts, with a fresh before attempt
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And a step policy "tx" defines the hook "before attempt"
    And the hook "before attempt" of policy "tx" fails with "no connection" on attempt 1
    When the workflow runs
    Then the events include, in order:
      | event              | step   | attempt | policy | hook           | cause              |
      | before_hook_failed | charge | 1       | tx     | before attempt |                    |
      | step_retrying      | charge | 1       |        |                | before hook failed |
      | attempt_started    | charge | 2       |        |                |                    |
      | hook_called        | charge | 2       | tx     | before attempt |                    |
      | step_succeeded     | charge | 2       |        |                |                    |
    And the hook "before attempt" of policy "tx" was called 2 times
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  Scenario: A step with a rescue step is rescued when its before attempt fails
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And a step policy "tx" defines the hook "before attempt"
    And the hook "before attempt" of policy "tx" fails with "no connection" on attempt 1
    When the workflow runs
    Then the events include, in order:
      | event              | step          | attempt | cause              | rescue        |
      | before_hook_failed | charge        | 1       |                    |               |
      | step_rescuing      | charge        | 1       | before hook failed | charge_rescue |
      | attempt_started    | charge_rescue | 1       |                    |               |
      | step_succeeded     | charge_rescue | 1       |                    |               |
      | step_rescued       | charge        | 1       |                    | charge_rescue |
      | attempt_started    | charge        | 2       |                    |               |
      | step_succeeded     | charge        | 2       |                    |               |
    And the journey succeeded

  Scenario: A failing after attempt after a success goes the abnormal termination path and is retried
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | contributes        |
      | 1       | success | {"receipt": "R-1"} |
      | 2       | success | {"receipt": "R-2"} |
    And its step policies and their hooks are:
      | policy | hook          | fails with    | on attempt | requests    |
      | tx     | after attempt | commit failed | 1          |             |
      | tx     | on step retry |               |            | retry cause |
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the events include, in order:
      | event                  | step   | attempt | key     | policy | hook          | cause             | error         |
      | step_succeeded         | charge | 1       |         |        |               |                   |               |
      | after_hook_failed      | charge | 1       |         | tx     | after attempt |                   | commit failed |
      | hook_called            | charge | 1       |         | tx     | on step retry |                   |               |
      | step_retrying          | charge | 1       |         |        |               | after hook failed |               |
      | attempt_started        | charge | 2       |         |        |               |                   |               |
      | step_succeeded         | charge | 2       |         |        |               |                   |               |
      | contribution_committed | charge | 2       | receipt |        |               |                   |               |
    And the hook "on step retry" of policy "tx" received the cause "after hook failed"
    And the reporter "trace" did not receive the event "step_abnormal_termination"
    And the reporter "trace" received the event "contribution_committed" 1 times
    And the result's data bag contains:
      | key     | value |
      | receipt | "R-2" |
    And the journey succeeded

  Scenario: A failing after attempt after a success with no retry budget gives the step up, and nothing is committed
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook            | fails with    |
      | tx     | after attempt   | commit failed |
      | tx     | on step success |               |
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | cause             | error         |
      | step_succeeded    | charge | 1       |                   |               |
      | after_hook_failed | charge | 1       |                   | commit failed |
      | step_given_up     | charge | 1       | after hook failed |               |
      | journey_failed    | charge |         | after hook failed |               |
    And the hook "on step success" of policy "tx" was not called
    And no contribution of "receipt" was committed
    And step "charge" ended as failed after 1 attempts
    And the result's failure has the cause "after hook failed"
    And the result's failure carries the error "commit failed"

  Scenario: A failing after attempt after a failure is recorded and changes nothing
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" fails with "rollback failed"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | cause   | error           |
      | step_failed       | charge | 1       |         |                 |
      | after_hook_failed | charge | 1       |         | rollback failed |
      | step_given_up     | charge | 1       | failure |                 |
      | journey_failed    | charge |         | failure |                 |
    And the result names the failed step "charge" with the code "declined"
    And the result's failure has the cause "failure"

  Scenario: A failing after step after a success gives the step up, and on step failure runs
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook            | fails with    |
      | tx     | after step      | settle failed |
      | tx     | on step success |               |
      | tx     | on step failure |               |
    When the workflow runs
    Then the events include, in order:
      | event             | step   | policy | hook            | cause             | error         |
      | step_succeeded    | charge |        |                 |                   |               |
      | after_hook_failed | charge | tx     | after step      |                   | settle failed |
      | step_given_up     | charge |        |                 | after hook failed |               |
      | hook_called       | charge | tx     | on step failure |                   |               |
      | journey_failed    | charge |        |                 | after hook failed |               |
    And the hook "on step success" of policy "tx" was not called
    And no contribution of "receipt" was committed
    And step "charge" ended as failed after 1 attempts
    And the result's failure has the cause "after hook failed"
    And the result's failure carries the error "settle failed"

  Scenario: A failing after journey after a success fails the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And its workflow policies and their hooks are:
      | policy | hook                | fails with |
      | audit  | after journey       | audit down |
      | audit  | on workflow success |            |
      | audit  | on workflow failure |            |
    And the workflow has the policies "audit"
    When the workflow runs
    Then the events include, in order:
      | event             | policy | hook                | cause             | error      | decided by |
      | after_hook_failed | audit  | after journey       |                   | audit down |            |
      | hook_called       | audit  | on workflow failure |                   |            |            |
      | journey_failed    |        |                     | after hook failed |            | default    |
    And journey_failed names no step
    And the hook "on workflow success" of policy "audit" was not called
    And step "charge" ended as succeeded after 1 attempts
    And the journey failed
    And the result's failure has the cause "after hook failed"
    And the result's failure carries the error "audit down"

  Scenario: One of two after attempt hooks failing does not stop the other
    Given a workflow "orders" with the steps:
      | step   | policies  |
      | charge | tx, audit |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And its step policies and their hooks are:
      | policy | hook          | fails with |
      | tx     | after attempt |            |
      | audit  | after attempt | audit down |
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook          |
      | audit  | after attempt |
      | tx     | after attempt |
    And the result names the failed step "charge" with the code "declined"

  Scenario: When several after hooks of a level fail, the first failure's error is carried, and the others receive the ending the level began with
    Given a workflow "orders" with the steps:
      | step   | policies  |
      | charge | tx, audit |
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook       | fails with     | requests |
      | tx     | after step | second failure | ending   |
      | audit  | after step | first failure  |          |
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook       |
      | audit  | after step |
      | tx     | after step |
    And the hook "after step" of policy "tx" received the endings "succeeded"
    And the result's failure has the cause "after hook failed"
    And the result's failure carries the error "first failure"

  Scenario: The after hooks of a before hook that failed still run, and those of a before hook never called do not
    Given a workflow "orders" with the steps:
      | step   | policies               |
      | charge | tx, lock, meter, trail |
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook        | fails with |
      | tx     | before step |            |
      | tx     | after step  |            |
      | lock   | before step | no lock    |
      | lock   | after step  |            |
      | meter  | before step |            |
      | meter  | after step  |            |
      | trail  | after step  |            |
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook        |
      | tx     | before step |
      | lock   | before step |
      | trail  | after step  |
      | lock   | after step  |
      | tx     | after step  |
    And the hook "before step" of policy "meter" was not called
    And the hook "after step" of policy "meter" was not called
