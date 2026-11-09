@tier-2 @proposal-0135
Feature: The attempt timeout
  Checks proposal 0135 (journey and attempt timeouts): an attempt timeout on a
  step descriptor limits how long one attempt may take, measured on the
  executor's clock from right after the attempt's `before attempt` hooks until
  the step's run returns, so input adapters and service providers count. An
  attempt that takes more than its timeout timed out, whatever it returned:
  its outcome fact, then `attempt_timed_out`, its `after attempt` hooks with
  the ending `timed out`, its contributions discarded, and the step given up
  with the cause `attempt timed out`, with no retry, rescue or deferral, then
  `after step` and `on step failure`. It never interrupts the attempt. The
  runner's clock moves on by what an attempt, an adapter, a provider or a hook
  is scripted to take, as well as when the executor waits.

  Scenario: An attempt that takes exactly its timeout is within it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 1000 ms |
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the reporter "trace" did not receive the event "attempt_timed_out"
    And the journey succeeded

  @proposal-0133
  Scenario: An attempt that succeeds just over its timeout fails the step, and nothing is committed
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" attempts:
      | attempt | outcome | takes   | contributes        |
      | 1       | success | 1001 ms | {"receipt": "R-1"} |
    And its step policies and their hooks are:
      | policy | hook            | requests |
      | tx     | after attempt   | ending   |
      | tx     | after step      | ending   |
      | tx     | on step success |          |
      | tx     | on step failure |          |
    When the workflow runs
    Then the events include, in order:
      | event                   | step   | attempt | policy | hook            | timeout | taken | cause             | decided by |
      | step_succeeded          | charge | 1       |        |                 |         |       |                   |            |
      | attempt_timed_out       | charge | 1       |        |                 | 1000    | 1001  |                   |            |
      | hook_called             | charge | 1       | tx     | after attempt   |         |       |                   |            |
      | contributions_discarded | charge | 1       |        |                 |         |       |                   |            |
      | step_given_up           | charge | 1       |        |                 |         |       | attempt timed out | default    |
      | hook_called             | charge |         | tx     | after step      |         |       |                   |            |
      | hook_called             | charge | 1       | tx     | on step failure |         |       |                   |            |
      | journey_failed          | charge |         |        |                 |         |       | attempt timed out | default    |
    And the hook "after attempt" of policy "tx" received the endings "timed out"
    And the hook "after step" of policy "tx" received the endings "failed"
    And the hook "on step success" of policy "tx" was not called
    And no contribution of "receipt" was committed
    And step "charge" ended as failed after 1 attempts
    And the journey failed
    And the result's failure has the cause "attempt timed out"
    And the result's failure carries no reason
    And the result's failure carries no error

  Scenario: An attempt over its timeout is not retried, whatever retry budget is left
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        | takes   |
      | 1       | failure | unreachable | 2000 ms |
    And a step policy "tx" defines the hook "on step retry"
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | cause             |
      | step_failed       | charge | 1       |                   |
      | attempt_timed_out | charge | 1       |                   |
      | step_given_up     | charge | 1       | attempt timed out |
    And the hook "on step retry" of policy "tx" was not called
    And the reporter "trace" did not receive the event "step_retrying"
    And step "charge" ended as failed after 1 attempts

  Scenario: An attempt over its timeout is not rescued
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    | takes   |
      | 1       | failure | expired | 2000 ms |
    And step "charge_rescue" succeeds
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the reporter "trace" did not receive the event "step_rescuing"
    And step "charge_rescue" was built 0 times, each time as a new instance
    And the result's failure has the cause "attempt timed out"

  @proposal-0134
  Scenario: A pending attempt over its timeout is not deferred
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has an attempt timeout of 1000 ms
    And step "payment" attempts:
      | attempt | outcome | takes   |
      | 1       | pending | 2000 ms |
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the events include, in order:
      | event             | step    | attempt | cause             |
      | step_pending      | payment | 1       |                   |
      | attempt_timed_out | payment | 1       |                   |
      | step_given_up     | payment | 1       | attempt timed out |
    And the reporter "trace" did not receive the event "step_deferred"

  Scenario: The time input adapters and service providers take counts against the attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" requests input "amount" of type integer
    And step "charge" requests the service "labels" of type labeller
    And step "charge" succeeds
    And the workflow declares the input adapter "prices" for the steps "charge"
    And the input adapter "prices" returns 42 for "amount"
    And the input adapter "prices" takes 600 ms for "amount"
    And the workflow declares the service provider "stock" for "labels" of type labeller, for each attempt
    And the service provider "stock" takes 600 ms
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | timeout | taken |
      | step_succeeded    | charge | 1       |         |       |
      | attempt_timed_out | charge | 1       | 1000    | 1200  |
    And the result's failure has the cause "attempt timed out"

  @proposal-0133
  Scenario: The time before attempt hooks take does not count against the attempt
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" attempts:
      | attempt | outcome | takes  |
      | 1       | success | 500 ms |
    And a step policy "tx" defines the hook "before attempt"
    And the hook "before attempt" of policy "tx" takes 2000 ms
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the reporter "trace" did not receive the event "attempt_timed_out"
    And the journey succeeded

  Scenario: The attempt timeout does not apply to the rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 5000 ms |
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the reporter "trace" did not receive the event "attempt_timed_out"
    And the journey succeeded

  Scenario: FailWorkflow from on step failure after a timed out attempt keeps the cause attempt timed out on step_given_up
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" has an attempt timeout of 1000 ms
    And step "charge" attempts:
      | attempt | outcome | takes   |
      | 1       | success | 2000 ms |
    And a step policy "tx" defines the hook "on step failure"
    And the hook "on step failure" of policy "tx" returns FailWorkflow with code "too slow"
    When the workflow runs
    Then the events include, in order:
      | event          | step   | cause             | decided by          |
      | step_given_up  | charge | attempt timed out | default             |
      | journey_failed | charge |                   | tx, on step failure |
    And the result names the step "charge" whose hook failed the journey, with the code "too slow"
