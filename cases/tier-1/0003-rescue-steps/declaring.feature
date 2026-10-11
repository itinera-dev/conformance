@tier-1 @proposal-0003
Feature: Declaring a rescue step
  Checks proposal 0003 (Rescue steps): a step has at most one rescue step, named
  after it with the suffix "_rescue", and a step with a rescue step is never
  retried. Both are checked when the workflow is built, and the listing shows
  each step's rescue step.

  @proposal-0042
  Scenario: A step with a rescue step and a retry budget is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation            |
      | rescued step retried |
    And no event was emitted

  @proposal-0042
  Scenario: A declared step with the name of a rescue step is a duplicate step name
    Given a workflow "orders" with the steps:
      | step          |
      | charge        |
      | charge_rescue |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation           |
      | duplicate step name |
    And no event was emitted

  @proposal-0060 @proposal-0042
  Scenario: An input adapter cannot be attached to a rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And the workflow declares the input adapter "pricing" for the steps "charge_rescue"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation                      |
      | input adapter for unknown step |
    And no event was emitted

  @proposal-0060
  Scenario: The listing shows each step's rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And step "ship" succeeds
    When the workflow is listed
    Then the listing is:
      | step   | position | policies | adapter | rescue        |
      | charge | 1        |          |         | charge_rescue |
      | ship   | 2        |          |         |               |
    And no step ran
