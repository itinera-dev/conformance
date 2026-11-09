@tier-1 @proposal-0002
Feature: Listing a workflow
  Checks section 2 of proposal 0002 (Foundations): a workflow's steps, their
  order, and the policies and adapters attached to them can be listed without
  running anything.

  @proposal-0060
  Scenario: A workflow is listed without running any step
    Given the step policies and their hooks:
      | policy | hook            |
      | audit  | on step success |
      | alarm  | on step failure |
    Given the input adapter "pricing" returns 7 when step "charge" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | policies     | inputs          | outcome |
      | charge | audit, alarm | amount: integer | success |
      | ship   |              |                 | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    When the workflow is listed
    Then the listing is:
      | step   | position | policies     | adapter |
      | charge | 1        | audit, alarm | pricing |
      | ship   | 2        |              |         |
    And no step ran
