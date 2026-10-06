@tier-1 @proposal-0002
Feature: Listing a workflow
  Checks section 2 of proposal 0002 (Foundations): a workflow's steps, their
  order, and the policies and adapters attached to them can be listed without
  running anything.

  @proposal-0060
  Scenario: A workflow is listed without running any step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And step "ship" succeeds
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" returns 7 for "amount"
    And a step policy "audit" defines the hook "on step success"
    And a step policy "alarm" defines the hook "on step failure"
    And step "charge" has the policies "audit", "alarm"
    When the workflow is listed
    Then the listing is:
      | step   | position | policies     | adapter |
      | charge | 1        | audit, alarm | pricing |
      | ship   | 2        |              |         |
    And no step ran
