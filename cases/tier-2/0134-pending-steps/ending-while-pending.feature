@tier-2 @proposal-0134
Feature: A journey that ends while steps are pending
  Checks proposal 0134 (pending steps): a failure or `FinishWorkflow` ends the
  journey at once. The step that ended it finishes as usual, up to its last
  hook; then each `Pending` or `Waiting` step, in reverse order of when its
  turn began, gets `step_abandoned`, decided by the hook that ended the
  journey or by `default`, then its `after step` hooks with the ending
  `abandoned`; then the journey's end. An abort ends the journey at once with no
  `step_abandoned`, and a `Pending` or `Waiting` step becomes `Aborted`.

  Scenario: A failure abandons the pending steps, the last to begin first
    Given a step policy "alarm" defines the hook "on step failure"
    Given a workflow "orders" with the steps:
      | step     | policies |
      | payment  |          |
      | invoice  |          |
      | shipping | alarm    |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And step "invoice" may be pending, with a pending budget of 3
    And step "invoice" attempts:
      | attempt | outcome |
      | 1       | pending |
    And step "shipping" attempts:
      | attempt | outcome | code     |
      | 1       | failure | no stock |
    When the workflow runs
    Then the events include, in order:
      | event          | step     | attempt | policy | hook            | status before | ending | cause   | decided by |
      | step_given_up  | shipping | 1       |        |                 |               |        | failure |            |
      | hook_called    | shipping | 1       | alarm  | on step failure |               |        |         |            |
      | step_abandoned | invoice  |         |        |                 | Pending       | failed |         | default    |
      | step_abandoned | payment  |         |        |                 | Pending       | failed |         | default    |
      | journey_failed | shipping |         |        |                 |               |        | failure |            |
    And step "payment" ended as abandoned after 1 attempts
    And step "invoice" ended as abandoned after 1 attempts
    And step "shipping" ended as failed after 1 attempts
    And the result names the failed step "shipping" with the code "no stock"

  @proposal-0133
  Scenario: An abandoned step runs its after step hooks with the ending abandoned
    Given the step policies and their hooks:
      | policy | hook       |
      | tx     | after step |
    Given a workflow policy "audit" defines the hook "after journey"
    And the hook "after step" of policy "tx" requests its ending
    Given a workflow "orders" with the policies "audit" and the steps:
      | step     | policies |
      | payment  | tx       |
      | shipping |          |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And step "shipping" attempts:
      | attempt | outcome | code     |
      | 1       | failure | no stock |
    When the workflow runs
    Then the events include, in order:
      | event          | step     | policy | hook          |
      | step_given_up  | shipping |        |               |
      | step_abandoned | payment  |        |               |
      | hook_called    | payment  | tx     | after step    |
      | hook_called    |          | audit  | after journey |
      | journey_failed | shipping |        |               |
    And the hook "after step" of policy "tx" received the endings "abandoned"

  Scenario: FinishWorkflow abandons the pending steps, decided by the hook that returned it
    Given the step policies and their hooks:
      | policy | hook            | returns        |
      | done   | on step success | FinishWorkflow |
    Given a workflow "orders" with the steps:
      | step     | policies | outcome |
      | payment  |          |         |
      | shipping | done     | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    When the workflow runs
    Then the events include, in order:
      | event             | step     | attempt | policy | hook            | status before | ending    | decided by            |
      | hook_called       | shipping | 1       | done   | on step success |               |           |                       |
      | step_abandoned    | payment  |         |        |                 | Pending       | succeeded | done, on step success |
      | journey_succeeded |          |         |        |                 |               |           | done, on step success |
    And step "payment" ended as abandoned after 1 attempts
    And the journey succeeded

  Scenario: An awaited step that fails ends the journey, and the step waiting for it is abandoned
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment |         |
      | receipt | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome | code     |
      | 1       | pending |          |
      | 2       | failure | declined |
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    When the workflow runs
    Then the events include, in order:
      | event          | step    | attempt | status before | decided by |
      | step_waiting   | receipt |         |               |            |
      | step_selected  | payment | 2       |               |            |
      | step_given_up  | payment | 2       |               |            |
      | step_abandoned | receipt |         | Waiting       | default    |
      | journey_failed | payment |         |               |            |
    And step "receipt" ended as abandoned after 0 attempts
    And step "receipt" was built 0 times, each time as a new instance
    And the result names the failed step "payment" with the code "declined"

  @proposal-0133
  Scenario: An abort while a step is pending emits no step_abandoned, and the pending step is aborted
    Given the step policies and their hooks:
      | policy | hook       |
      | tx     | after step |
    And the hook "after step" of policy "tx" requests its ending
    Given a workflow "orders" with the steps:
      | step     | policies | inputs          | outcome |
      | payment  | tx       |                 |         |
      | shipping |          | address: string | success |
    And the workflow allows pending steps
    And the workflow lists the reporters "trace"
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And the data bag is empty
    When the workflow runs
    Then the reporter "trace" did not receive the event "step_abandoned"
    And the last event is "journey_aborted"
    And the hook "after step" of policy "tx" received the endings "aborted"
    And step "payment" ended as aborted after 1 attempts
    And the journey was aborted with the abort reason "required data missing"
