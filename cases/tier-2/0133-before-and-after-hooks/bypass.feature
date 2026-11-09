@tier-2 @proposal-0133
Feature: A before step hook that bypasses its step
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): `before step` returns nothing, which continues, or a bypass with an
  optional reason. The first that bypasses wins, and the later ones are not
  called. A bypassed step is not built, no input adapter or service provider is
  called for it, and it has no attempt; its status becomes `Bypassed`,
  `step_bypassed` is decided by that policy and hook, the `after step` hooks of
  the policies whose `before step` was called run, and the journey moves on. A
  lifecycle from `before step` is an `invalid lifecycle`.

  Scenario: The second of three before step hooks bypasses the step
    Given the step policies and their hooks:
      | policy | hook        | returns | code              |
      | first  | before step |         |                   |
      | first  | after step  |         |                   |
      | gate   | before step | bypass  | no discount today |
      | gate   | after step  |         |                   |
      | last   | before step |         |                   |
      | last   | after step  |         |                   |
    And the service provider "stock" makes a labeller for "labels", for each attempt
    And a workflow "orders" with the steps:
      | step     | policies          | services         | outcome |
      | discount | first, gate, last | labels: labeller | success |
      | ship     |                   |                  | success |
    And the workflow binds the service provider "stock" to the steps "discount"
    And the workflow binds the input adapter "prices" to the steps "discount"
    When the workflow runs
    Then the events include, in order:
      | event           | step     | attempt | policy | hook        | lifecycle | code              | decided by        |
      | hook_called     | discount |         | first  | before step | none      |                   |                   |
      | hook_called     | discount |         | gate   | before step | bypass    |                   |                   |
      | step_bypassed   | discount |         |        |             |           | no discount today | gate, before step |
      | hook_called     | discount |         | gate   | after step  |           |                   |                   |
      | hook_called     | discount |         | first  | after step  |           |                   |                   |
      | attempt_started | ship     | 1       |        |             |           |                   |                   |
    And the hooks received:
      | policy | hook        | calls |
      | last   | before step | 0     |
      | last   | after step  | 0     |
    And the service provider "stock" was called 0 times
    And the input adapter "prices" was called 0 times
    And step "discount" was built 0 times, each time as a new instance
    And step "discount" ended as bypassed after 0 attempts
    And step "ship" ended as succeeded after 1 attempts
    And the journey succeeded

  Scenario: A bypass without a reason bypasses the step
    Given the step policies and their hooks:
      | policy | hook        | returns |
      | gate   | before step | bypass  |
    And a workflow "orders" with the steps:
      | step     | policies | outcome |
      | discount | gate     | success |
    When the workflow runs
    Then the events include, in order:
      | event             | step     | decided by        |
      | step_bypassed     | discount | gate, before step |
      | journey_succeeded |          |                   |
    And step "discount" ended as bypassed after 0 attempts
    And the journey succeeded

  Scenario: A bypassed step's contributions never reach the data bag, and its outcome hooks are not called
    Given the step policies and their hooks:
      | policy | hook            | returns | code |
      | gate   | before step     | bypass  | off  |
      | gate   | on step success |         |      |
    And a workflow "orders" with the steps:
      | step     | policies | outcome |
      | discount | gate     | success |
    And step "discount" contributes "rate" = 10
    When the workflow runs
    Then the hook "on step success" of policy "gate" was not called
    And no contribution of "rate" was committed
    And the result's data bag has no key "rate"
    And the journey succeeded

  @invalid-lifecycle
  Scenario: A lifecycle returned by before step aborts the journey with invalid lifecycle
    Given the step policies and their hooks:
      | policy | hook        | returns        |
      | gate   | before step | FinishWorkflow |
      | gate   | after step  |                |
    And a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | gate     | success |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | policy | hook        | code              |
      | journey_aborted | charge | gate   | before step | invalid lifecycle |
    And the hooks were called in this order:
      | policy | hook        |
      | gate   | before step |
      | gate   | after step  |
    And the journey was aborted with the abort reason "invalid lifecycle"
