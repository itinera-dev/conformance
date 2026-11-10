@tier-1 @proposal-0003
Feature: Declaring a rescue step
  Checks proposal 0003 (Rescue steps): a step has at most one rescue step, named
  after it with the suffix "_rescue", and a step with a rescue step is never
  retried. Both are checked when the workflow is built, and the listing shows
  each step's rescue step.
  Proposal 0098 amends it: an input adapter may be attached to a rescue step by
  its name, and the listing shows, in the entry of a step with a rescue step, a
  rescue section with the rescue step's name, its adapter and its services.

  @proposal-0042
  Scenario: A step with a rescue step and a retry budget is refused
    Given a workflow "orders" with the steps:
      | step   | outcome | rescue |
      | charge | success | yes    |
    And step "charge" allows 1 retries
    And step "charge_rescue" succeeds
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation            |
      | rescued step retried |
    And no event was emitted

  @proposal-0042
  Scenario: A declared step with the name of a rescue step is a duplicate step name
    Given a workflow "orders" with the steps:
      | step          | outcome | rescue |
      | charge        | success | yes    |
      | charge_rescue | success |        |
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation           |
      | duplicate step name |
    And no event was emitted

  @proposal-0060 @proposal-0098
  Scenario: An input adapter attached to a rescue step's name supplies the rescue step's input
    Given the input adapter "credentials" returns "fresh" when step "charge_rescue" requests "token"
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And the workflow binds the input adapter "credentials" to the step "charge_rescue"
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests input "token" of type string
    And step "charge_rescue" succeeds
    And the data bag contains:
      | key   | value   |
      | token | "stale" |
    When the workflow runs
    Then step "charge_rescue" was built with input "token" = "fresh"
    And the events include, in order:
      | event                  | step          | attempt | key   | adapter     |
      | step_rescuing          | charge        | 1       |       |             |
      | attempt_started        | charge_rescue | 1       |       |             |
      | input_adapter_supplied | charge_rescue |         | token | credentials |
      | step_succeeded         | charge_rescue | 1       |       |             |
      | step_rescued           | charge        | 1       |       |             |
    And the journey succeeded

  @proposal-0060
  Scenario: The listing shows each step's rescue step
    Given a workflow "orders" with the steps:
      | step   | outcome | rescue |
      | charge | success | yes    |
      | ship   | success |        |
    And step "charge_rescue" succeeds
    When the workflow is listed
    Then the listing is:
      | step   | position | policies | adapter | rescue        |
      | charge | 1        |          |         | charge_rescue |
      | ship   | 2        |          |         |               |
    And no step ran

  @proposal-0060 @proposal-0095 @proposal-0098
  Scenario: The listing shows the rescue section, with the rescue step's adapter and services
    Given the service provider "payments" makes a labeller for "payments", once per journey
    Given the service provider "stock" makes a labeller for "stock", once per journey
    Given the service provider "backup payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | inputs          | services           | outcome | rescue |
      | charge | amount: integer | payments: labeller | success | yes    |
      | ship   |                 |                    | success |        |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the workflow binds the input adapter "credentials" to the step "charge_rescue"
    And the workflow binds the service provider "payments"
    And the workflow binds the service provider "stock"
    And the workflow binds the service provider "backup payments" to the step "charge_rescue"
    And step "charge_rescue" requests input "token" of type string
    And step "charge_rescue" requests the service "payments" of type labeller
    And step "charge_rescue" requests the service "stock" of type labeller
    And step "charge_rescue" succeeds
    When the workflow is listed
    Then the listing is:
      | step   | position | policies | adapter | services           | rescue        | rescue adapter | rescue services                         |
      | charge | 1        |          | pricing | payments: payments | charge_rescue | credentials    | payments: backup payments, stock: stock |
      | ship   | 2        |          |         |                    |               |                |                                         |
    And no step ran
