@tier-1 @proposal-0008
Feature: Skipped steps
  Checks items 12 to 16 of proposal 0008 (Steps): a step that reports Skipped
  is out of the flow, no hook reacts to it, it has no effect on data, and it is
  final.

  Scenario: A skipped step is out of the flow and the journey continues
    Given the step policies and their hooks:
      | policy | hook            |
      | policy | on step success |
      | alarm  | on step failure |
    Given a workflow "orders" with the steps:
      | step     | policies      | outcome |
      | discount | policy, alarm |         |
      | ship     |               | success |
    And step "discount" attempts:
      | attempt | outcome | code             |
      | 1       | skipped | no discount here |
    When the workflow runs
    Then the hooks received:
      | policy | hook            | calls |
      | policy | on step success | 0     |
      | alarm  | on step failure | 0     |
    And the steps ended as:
      | step     | status    | attempts |
      | discount | skipped   | 1        |
      | ship     | succeeded | 1        |
    And the events include, in order:
      | event        | step     | key | attempt | code             |
      | step_skipped | discount |     | 1       | no discount here |
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
      | contributions_discarded | discount |     | 1       |      |
    And the journey succeeded

  Scenario: A later step requiring what a skipped step would have contributed aborts the journey
    Given a workflow "orders" with the steps:
      | step     | inputs            | outcome |
      | discount |                   |         |
      | charge   | discount: integer | success |
    And step "discount" attempts:
      | attempt | outcome | contributes      |
      | 1       | skipped | {"discount": 10} |
    When the workflow runs
    Then the journey was aborted

  Scenario: A later step with an optional input receives it absent after a skip
    Given a workflow "orders" with the steps:
      | step     | outcome |
      | discount |         |
      | charge   | success |
    And step "discount" attempts:
      | attempt | outcome | contributes      |
      | 1       | skipped | {"discount": 10} |
    And step "charge" requests optional input "discount" of type integer
    When the workflow runs
    Then step "charge" was built with input "discount" absent
    And the journey succeeded
