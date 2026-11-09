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
    Given a workflow "orders" with the steps:
      | step     | policies          |
      | discount | first, gate, last |
      | ship     |                   |
    And step "discount" requests the service "labels" of type labeller
    And step "discount" succeeds
    And step "ship" succeeds
    And the workflow declares the service provider "stock" for "labels" of type labeller, for each attempt
    And the service provider "stock" serves only the steps "discount"
    And the workflow declares the input adapter "prices" for the steps "discount"
    And its step policies and their hooks are:
      | policy | hook        | returns | code              |
      | first  | before step |         |                   |
      | first  | after step  |         |                   |
      | gate   | before step | bypass  | no discount today |
      | gate   | after step  |         |                   |
      | last   | before step |         |                   |
      | last   | after step  |         |                   |
    When the workflow runs
    Then the events include, in order:
      | event           | step     | attempt | policy | hook        | lifecycle | code              | decided by        |
      | hook_called     | discount |         | first  | before step | none      |                   |                   |
      | hook_called     | discount |         | gate   | before step | bypass    |                   |                   |
      | step_bypassed   | discount |         |        |             |           | no discount today | gate, before step |
      | hook_called     | discount |         | gate   | after step  |           |                   |                   |
      | hook_called     | discount |         | first  | after step  |           |                   |                   |
      | attempt_started | ship     | 1       |        |             |           |                   |                   |
    And the hook "before step" of policy "last" was not called
    And the hook "after step" of policy "last" was not called
    And the service provider "stock" was called 0 times
    And the input adapter "prices" was called 0 times
    And step "discount" was built 0 times, each time as a new instance
    And step "discount" ended as bypassed after 0 attempts
    And step "ship" ended as succeeded after 1 attempts
    And the journey succeeded

  Scenario: A bypass without a reason bypasses the step
    Given a workflow "orders" with the steps:
      | step     | policies |
      | discount | gate     |
    And step "discount" succeeds
    And a step policy "gate" defines the hook "before step"
    And the hook "before step" of policy "gate" bypasses
    When the workflow runs
    Then the events include, in order:
      | event             | step     | decided by        |
      | step_bypassed     | discount | gate, before step |
      | journey_succeeded |          |                   |
    And step "discount" ended as bypassed after 0 attempts
    And the journey succeeded

  Scenario: A bypassed step's contributions never reach the data bag, and its outcome hooks are not called
    Given a workflow "orders" with the steps:
      | step     | policies |
      | discount | gate     |
    And step "discount" contributes "rate" = 10
    And step "discount" succeeds
    And its step policies and their hooks are:
      | policy | hook            | returns | code |
      | gate   | before step     | bypass  | off  |
      | gate   | on step success |         |      |
    When the workflow runs
    Then the hook "on step success" of policy "gate" was not called
    And no contribution of "rate" was committed
    And the result's data bag has no key "rate"
    And the journey succeeded

  @invalid-lifecycle
  Scenario: A lifecycle returned by before step aborts the journey with invalid lifecycle
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | gate     |
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook        | returns        |
      | gate   | before step | FinishWorkflow |
      | gate   | after step  |                |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | policy | hook        | code              |
      | journey_aborted | charge | gate   | before step | invalid lifecycle |
    And the hooks were called in this order:
      | policy | hook        |
      | gate   | before step |
      | gate   | after step  |
    And the journey was aborted with the abort reason "invalid lifecycle"
