@tier-1 @proposal-0008
Feature: Skipped steps
  Checks items 12 to 16 of proposal 0008 (Steps): a step that reports Skipped
  is out of the flow, no hook reacts to it, it has no effect on data, and it is
  final.

  Scenario: A skipped step is out of the flow and the journey continues
    Given a workflow "orders" with the steps:
      | step     |
      | discount |
      | ship     |
    And step "discount" attempts:
      | attempt | outcome | code             |
      | 1       | skipped | no discount here |
    And step "ship" succeeds
    And a step policy "policy" defines the hook "on step success"
    And a step policy "alarm" defines the hook "on step failure"
    And step "discount" has the policies "policy", "alarm"
    When the workflow runs
    Then the hook "on step success" of policy "policy" was not called
    And the hook "on step failure" of policy "alarm" was not called
    And step "discount" ended as skipped after 1 attempts
    And step "ship" ended as succeeded after 1 attempts
    And the events include, in order:
      | event        | step     | key | attempt | code             |
      | step skipped | discount |     | 1       | no discount here |
    And the journey succeeded

  Scenario: A skipped step's contributions are discarded
    Given a workflow "orders" with the steps:
      | step     |
      | discount |
    And step "discount" attempts:
      | attempt | outcome | contributes        |
      | 1       | skipped | {"discount": 10}   |
    When the workflow runs
    Then the result's data bag has no key "discount"
    And the events include, in order:
      | event                  | step     | key | attempt | code |
      | contributions discarded | discount |     | 1       |      |
    And the journey succeeded

  Scenario: A later step requiring what a skipped step would have contributed aborts the journey
    Given a workflow "orders" with the steps:
      | step     |
      | discount |
      | charge   |
    And step "discount" attempts:
      | attempt | outcome | contributes      |
      | 1       | skipped | {"discount": 10} |
    And step "charge" requests input "discount" of type integer
    And step "charge" succeeds
    When the workflow runs
    Then the journey was aborted

  Scenario: A later step with an optional input receives it absent after a skip
    Given a workflow "orders" with the steps:
      | step     |
      | discount |
      | charge   |
    And step "discount" attempts:
      | attempt | outcome | contributes      |
      | 1       | skipped | {"discount": 10} |
    And step "charge" requests optional input "discount" of type integer
    And step "charge" succeeds
    When the workflow runs
    Then step "charge" was built with input "discount" absent
    And the journey succeeded
