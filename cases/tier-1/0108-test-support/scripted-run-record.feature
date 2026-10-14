@tier-1 @proposal-0108 @capability-testing
Feature: A scripted run records each attempt handed to its step
  Checks proposal 0108 (Test support): a scripted run returns the journey's
  result with a record of every step and rescue step of the workflow, holding
  in order each attempt handed to the construction of its step, scripted or
  real, and what that attempt's step was built with.

  Scenario: The record holds every attempt, scripted or real, with its inputs
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And step "charge" allows 1 retries
    And step "ship" succeeds
    And the data bag contains:
      | key    | value |
      | amount | 40    |
    And the script says:
      | step   | attempt | ending   | code     |
      | charge | 1       | failure  | declined |
      | charge | 2       | real run |          |
    When the workflow runs with the script
    Then the scripted run's record of step "charge" holds the attempts 1, 2
    And attempt 1 of step "charge" in the scripted run's record read the input "amount" = 40
    And attempt 2 of step "charge" in the scripted run's record read the input "amount" = 40
    And the scripted run's record of step "ship" holds the attempts 1

  Scenario: A step that never runs has no attempt in the record
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | 1       | failure | declined |
    When the workflow runs with the script
    Then the journey failed
    And the scripted run's record of step "ship" holds no attempt

  Scenario: An attempt whose step's constructor failed is in the record
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" cannot be built because its constructor fails with "broken"
    And the script says:
      | step   | attempt | ending  |
      | charge | 1       | success |
    When the workflow runs with the script
    Then the journey was aborted with the abort reason "step could not be built"
    And the scripted run's record of step "charge" holds the attempts 1

  Scenario: A failing service provider keeps the attempt out of the record
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" fails with "gateway down"
    And the script says:
      | step   | attempt | ending  |
      | charge | 1       | success |
    When the workflow runs with the script
    Then the journey was aborted with the abort reason "step could not be built"
    And the scripted run's record of step "charge" holds no attempt

  Scenario: A missing required input keeps the attempt out of the record
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    And the script says:
      | step   | attempt | ending  |
      | charge | 1       | success |
    When the workflow runs with the script
    Then the journey was aborted with the abort reason "required data missing"
    And the scripted run's record of step "charge" holds no attempt

  Scenario: A rescue step's attempt reads the contributions it requested from the failed attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" requests rescued step data "card" of type string
    And step "charge_rescue" succeeds
    And the script says:
      | step          | attempt | contributes         | ending  | code    |
      | charge        | 1       | {"card": "expired"} | failure | expired |
      | charge        | 2       |                     | success |         |
      | charge_rescue | 1       |                     | success |         |
    When the workflow runs with the script
    Then the scripted run's record of step "charge_rescue" holds the attempts 1
    And attempt 1 of step "charge_rescue" in the scripted run's record read the rescued step data "card" = "expired"
