@tier-2 @proposal-0134
Feature: The hint a pending step attaches
  Checks proposal 0134 (pending steps): a step reporting pending may attach a
  hint, a value such as the "retry after" an external system gave it.
  `step_pending` carries the hint's value, and `on step pending` may request
  it: the step suggests, and the workflow decides. A hint that is not a value
  aborts the journey with `not a value`.

  Scenario: step_pending carries the hint, and on step pending receives it
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome | hint                |
      | 1       | pending | {"retry after": 30} |
      | 2       | success |                     |
    And a step policy "pace" defines the hook "on step pending"
    And the hook "on step pending" of policy "pace" requests the hint
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the events include, in order:
      | event        | step    | attempt | hint                |
      | step_pending | payment | 1       | {"retry after": 30} |
    And the hook "on step pending" of policy "pace" received the hint {"retry after": 30}
    And the journey succeeded

  Scenario: On step pending receives no hint when the step attached none
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And a step policy "pace" defines the hook "on step pending"
    And the hook "on step pending" of policy "pace" requests the hint
    And step "payment" has the policies "pace"
    When the workflow runs
    Then the hook "on step pending" of policy "pace" received no hint
    And the journey succeeded

  @non-value
  Scenario: A hint that is not a value aborts the journey with not a value
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" reports pending with a hint that is not a value
    When the workflow runs
    Then the events include, in order:
      | event           | step    | code        |
      | journey_aborted | payment | not a value |
    And the journey was aborted with the abort reason "not a value"
