@tier-2 @proposal-0134
Feature: The pending budget, the pending deadline and on step pending
  Checks proposal 0134 (pending steps): with a pending budget of N, the first N
  pendings of a step are each deferred, after `on step pending`; on the
  pending after the Nth, `on step pending` is not called, the step is given up
  with the cause `pending exhausted`, saying `budget`, and then only `on step
  failure` runs. When the nbf decided for a pending falls after the step's
  pending deadline, counted from its first `step_pending`, the step is given up
  with `pending exhausted`, saying `deadline`. `on step pending` returns
  nothing, which keeps the defaults, a deferral with a new nbf delay, a new
  weight or both, or `FailWorkflow`; `FinishWorkflow` is an `invalid
  lifecycle`, and a negative delay an `unexpected result`. The runner's clock
  starts at 2026-01-01T00:00:00.000Z and moves only when the executor waits.

  Background:
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And the workflow allows pending steps

  Scenario: On step pending defers with a new nbf and a new weight
    Given step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And a step policy "pace" defines the hook "on step pending"
    And the hook "on step pending" of policy "pace" defers with nbf 2000 ms and weight 7
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the events include, in order:
      | event           | step    | attempt | policy | hook            | lifecycle | nbf  | nbf at                   | weight | decided by            |
      | step_pending    | payment | 1       |        |                 |           |      |                          |        |                       |
      | hook_called     | payment | 1       | pace   | on step pending | defer     |      |                          |        |                       |
      | step_deferred   | payment | 1       |        |                 |           | 2000 | 2026-01-01T00:00:02.000Z | 7      | pace, on step pending |
      | journey_waiting | payment |         |        |                 |           |      |                          |        |                       |
      | step_selected   | payment | 2       |        |                 |           |      |                          |        |                       |
    And the journey succeeded

  Scenario: On step pending that returns nothing keeps the defaults
    Given step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 1000 ms
    And step "payment" has a default weight of 4
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And a step policy "pace" defines the hook "on step pending"
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the events include, in order:
      | event         | step    | attempt | policy | hook            | lifecycle | nbf  | weight | decided by |
      | hook_called   | payment | 1       | pace   | on step pending | none      |      |        |            |
      | step_deferred | payment | 1       |        |                 |           | 1000 | 4      | default    |
    And the journey succeeded

  Scenario: The pending after the budget gives the step up, without calling on step pending
    Given step "payment" may be pending, with a pending budget of 1
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And the step policies define the hooks:
      | policy | hook            |
      | pace   | on step pending |
      | pace   | on step failure |
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the events include, in order:
      | event          | step    | attempt | policy | hook            | cause             | limit  | decided by |
      | step_pending   | payment | 1       |        |                 |                   |        |            |
      | hook_called    | payment | 1       | pace   | on step pending |                   |        |            |
      | step_deferred  | payment | 1       |        |                 |                   |        |            |
      | step_selected  | payment | 2       |        |                 |                   |        |            |
      | step_pending   | payment | 2       |        |                 |                   |        |            |
      | step_given_up  | payment | 2       |        |                 | pending exhausted | budget | default    |
      | hook_called    | payment | 2       | pace   | on step failure |                   |        |            |
      | journey_failed | payment |         |        |                 | pending exhausted |        |            |
    And the hook "on step pending" of policy "pace" was called 1 times
    And step "payment" ended as failed after 2 attempts
    And the journey failed
    And the result's failure has the cause "pending exhausted"
    And the result's failure carries no reason
    And the result's failure carries no error

  Scenario: A pending whose nbf falls after the deadline gives the step up
    Given step "payment" may be pending, with a pending budget of 5
    And step "payment" has a default nbf of 2000 ms
    And step "payment" has a pending deadline of 3000 ms
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And a step policy "pace" defines the hook "on step failure"
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the events include, in order:
      | event          | step    | attempt | nbf at                   | deadline                 | cause             | limit    | decided by | timestamp                |
      | step_pending   | payment | 1       |                          |                          |                   |          |            | 2026-01-01T00:00:00.000Z |
      | step_deferred  | payment | 1       | 2026-01-01T00:00:02.000Z | 2026-01-01T00:00:03.000Z |                   |          |            |                          |
      | step_pending   | payment | 2       |                          |                          |                   |          |            | 2026-01-01T00:00:02.000Z |
      | step_given_up  | payment | 2       |                          |                          | pending exhausted | deadline | default    |                          |
      | hook_called    | payment | 2       |                          |                          |                   |          |            |                          |
      | journey_failed | payment |         |                          |                          | pending exhausted |          |            |                          |
    And the hook "on step failure" of policy "pace" was called 1 times
    And step "payment" ended as failed after 2 attempts

  Scenario: FailWorkflow from on step pending gives the step up, and on step failure is not called
    Given step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And the step policies define the hooks:
      | policy | hook            | returns      | code     |
      | pace   | on step pending | FailWorkflow | too slow |
      | pace   | on step failure |              |          |
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the events include, in order:
      | event          | step    | attempt | cause        | decided by            |
      | step_pending   | payment | 1       |              |                       |
      | step_given_up  | payment | 1       | FailWorkflow | pace, on step pending |
      | journey_failed | payment |         |              | pace, on step pending |
    And the hook "on step failure" of policy "pace" was not called
    And step "payment" ended as failed after 1 attempts
    And the result names the step "payment" whose hook failed the journey, with the code "too slow"

  @invalid-lifecycle
  Scenario: FinishWorkflow from on step pending aborts the journey with invalid lifecycle
    Given step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And a step policy "pace" defines the hook "on step pending"
    And the hook "on step pending" of policy "pace" returns FinishWorkflow
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the journey was aborted with the abort reason "invalid lifecycle"

  @negative-delay
  Scenario: A negative nbf from on step pending aborts the journey with unexpected result
    Given step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And a step policy "pace" defines the hook "on step pending"
    And the hook "on step pending" of policy "pace" defers with nbf -1000 ms
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the journey was aborted with the abort reason "unexpected result"

  Scenario: On step pending receives the step's name and the attempt number
    Given step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And a step policy "pace" defines the hook "on step pending"
    And the hook "on step pending" of policy "pace" requests the step name
    And the hook "on step pending" of policy "pace" requests the attempt number
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the hook "on step pending" of policy "pace" received the step name "payment"
    And the hook "on step pending" of policy "pace" received the attempt number 1
    And the journey succeeded
