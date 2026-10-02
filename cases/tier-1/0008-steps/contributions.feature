@tier-1 @proposal-0008
Feature: Contributions
  Checks items 17 to 22 of proposal 0008 (Steps): contributions are visible to
  the attempt's hooks whatever the outcome, committed only on success, absent
  after an abnormal termination, the last value wins within an attempt, and
  overwriting the data bag is allowed and recorded.

  Scenario: Only a successful attempt's contributions are committed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        | contributes          |
      | 1       | retriable failure | unreachable | {"draft": "D-1"}     |
      | 2       | success           |             | {"receipt": "R-1"}   |
    When the workflow runs
    Then the result's data bag contains:
      | key     | value |
      | receipt | "R-1" |
    And the result's data bag has no key "draft"
    And the journey succeeded

  Scenario: A failed step's contributions are visible to its hooks but never committed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     | contributes                    |
      | 1       | failure | declined | {"decline": "insufficient"}    |
    And a step policy "policy" defines the hook "on step failure"
    And the hook "on step failure" of policy "policy" requests step data "decline" of type string
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the hook "on step failure" of policy "policy" received step data "decline" = "insufficient"
    And the result's data bag has no key "decline"
    And the journey failed

  Scenario: An abnormal termination carries no contributions
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | contributes      |
      | 1       | error   | {"draft": "D-1"} |
    And a step policy "policy" defines the hook "on step abnormal termination"
    And the hook "on step abnormal termination" of policy "policy" requests optional step data "draft" of type string
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the hook "on step abnormal termination" of policy "policy" received step data "draft" absent
    And the result's data bag has no key "draft"

  Scenario: The same key contributed twice in one attempt keeps the last value
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" contributes "receipt" = "R-2"
    And step "charge" succeeds
    When the workflow runs
    Then the result's data bag contains:
      | key     | value |
      | receipt | "R-2" |
    And the journey succeeded

  Scenario: A contribution may overwrite a key already in the data bag, and the overwrite is recorded
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the data bag contains:
      | key    | value |
      | amount | 1     |
    And step "charge" contributes "amount" = 2
    And step "charge" succeeds
    When the workflow runs
    Then the result's data bag contains:
      | key    | value |
      | amount | 2     |
    And the events include, in order:
      | event            | step   | key    | attempt | code |
      | data overwritten | charge | amount | 1       |      |
    And the journey succeeded
