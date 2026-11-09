@tier-2 @proposal-0134
Feature: The ordered pass and the scheduled pass
  Checks proposal 0134 (pending steps): a journey runs in passes. In the
  ordered pass, the scan of tier 1, every step gets its first run in declared
  order; a step that reports pending is deferred and becomes `Pending`, and the
  scan moves on. When the ordered pass ends with steps still `Pending` or
  `Waiting`, the scheduled pass starts and tries them again. `pass_started`
  is emitted once when each pass starts, for the ordered pass after
  `journey_started` and the `before journey` hooks, and for the scheduled pass
  with the steps still pending or waiting. A journey with no pending step has
  only the ordered pass. The runner's clock starts at
  2026-01-01T00:00:00.000Z and moves only when the executor waits.

  Scenario: The ordered pass moves past a pending step, and the scheduled pass returns to it
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | invoice |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "invoice" succeeds
    When the workflow runs
    Then the events include, in order:
      | event             | step    | attempt | pass      | steps   | status before | round | decided by |
      | journey_started   |         |         |           |         |               |       |            |
      | pass_started      |         |         | ordered   |         |               |       |            |
      | attempt_started   | payment | 1       |           |         |               |       |            |
      | step_pending      | payment | 1       |           |         |               |       |            |
      | step_deferred     | payment | 1       |           |         |               |       | default    |
      | attempt_started   | invoice | 1       |           |         |               |       |            |
      | step_succeeded    | invoice | 1       |           |         |               |       |            |
      | pass_started      |         |         | scheduled | payment |               |       |            |
      | step_selected     | payment | 2       |           |         | Pending       | 0     | default    |
      | attempt_started   | payment | 2       |           |         |               |       |            |
      | step_succeeded    | payment | 2       |           |         |               |       |            |
      | journey_succeeded |         |         |           |         |               |       |            |
    And step "payment" ended as succeeded after 2 attempts
    And step "invoice" ended as succeeded after 1 attempts
    And the journey succeeded

  Scenario: A journey with no pending step has only the ordered pass
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    When the workflow runs
    Then the events are exactly:
      | event             | step   | attempt | pass    |
      | journey_started   |        |         |         |
      | pass_started      |        |         | ordered |
      | attempt_started   | charge | 1       |         |
      | step_succeeded    | charge | 1       |         |
      | journey_succeeded |        |         |         |

  @proposal-0133
  Scenario: The ordered pass starts after the before journey hooks
    Given a workflow policy "audit" defines the hook "before journey"
    And a workflow "orders" with the policies "audit" and the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    When the workflow runs
    Then the events include, in order:
      | event           | step   | attempt | policy | hook           | pass    |
      | journey_started |        |         |        |                |         |
      | hook_called     |        |         | audit  | before journey |         |
      | pass_started    |        |         |        |                | ordered |
      | attempt_started | charge | 1       |        |                |         |

  @proposal-0133
  Scenario: A journey that fails in its before journey hooks has no pass
    Given the workflow policies and their hooks:
      | policy | hook           | returns      | code      |
      | check  | before journey | FailWorkflow | bad input |
    And a workflow "orders" with the policies "check" and the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the reporter "trace" did not receive the event "pass_started"
    And the journey failed

  Scenario: The scheduled pass starts only once the ordered pass has reached its end
    Given a workflow "orders" with the steps:
      | step     |
      | payment  |
      | invoice  |
      | shipping |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "invoice" may be pending, with a pending budget of 3
    And step "invoice" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "shipping" succeeds
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the events include, in order:
      | event          | step     | attempt | pass      | steps            |
      | step_deferred  | payment  | 1       |           |                  |
      | step_deferred  | invoice  | 1       |           |                  |
      | step_succeeded | shipping | 1       |           |                  |
      | pass_started   |          |         | scheduled | payment, invoice |
      | step_selected  | payment  | 2       |           |                  |
      | step_succeeded | payment  | 2       |           |                  |
      | step_selected  | invoice  | 2       |           |                  |
      | step_succeeded | invoice  | 2       |           |                  |
    And the reporter "trace" received the event "pass_started" 2 times
    And the journey succeeded
