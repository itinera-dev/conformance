@tier-1 @proposal-0002
Feature: Listing a workflow
  Checks section 2 of proposal 0002 (Foundations): a workflow's steps, their
  order, and the policies and adapters attached to them can be listed without
  running anything.

  Scenario: A workflow is listed without running any step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And step "ship" succeeds
    And the workflow declares an input adapter for step "charge" and key "amount" that returns 7
    And a step policy "audit" defines the hook "on step success"
    And a step policy "alarm" defines the hook "on step failure"
    And step "charge" has the policies "audit", "alarm"
    When the workflow is listed
    Then the listing is:
      | step   | position | policies     | adapters |
      | charge | 1        | audit, alarm | amount   |
      | ship   | 2        |              |          |
    And no step ran
