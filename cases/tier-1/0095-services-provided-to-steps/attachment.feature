@tier-1 @proposal-0095
Feature: Providers attached to steps
  Checks proposal 0095: a provider attached to steps serves only those steps,
  replacing for them the provider of the same key attached to no step, which
  serves every other step. A journey-scoped provider attached to steps makes one
  instance per journey, shared by those steps only. The listing shows which
  provider serves each step's services.

  Scenario: A provider attached to two steps serves them, and the other provider serves the rest
    Given the service provider "payments" makes a labeller for "payments", once per journey
    Given the service provider "fresh payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step    | services           | outcome |
      | reserve | payments: labeller | success |
      | charge  | payments: labeller | success |
      | refund  | payments: labeller | success |
      | ship    | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the workflow binds the service provider "fresh payments" to the steps "charge", "refund"
    When the workflow runs
    Then the steps were given the services:
      | step    | service  | label            | attempt |
      | reserve | payments | payments 1       | 1       |
      | charge  | payments | fresh payments 1 | 1       |
      | refund  | payments | fresh payments 2 | 1       |
      | ship    | payments | payments 1       | 1       |
    And the service provider "payments" was called 1 times
    And the service provider "fresh payments" was called 2 times
    And the events include, in order:
      | event            | step    | key      | provider       |
      | service_provided | reserve | payments | payments       |
      | service_provided | charge  | payments | fresh payments |
      | service_provided | refund  | payments | fresh payments |

  Scenario: A journey-scoped provider attached to steps is shared by those steps only
    Given the service provider "stock" makes a labeller for "stock", once per journey
    Given the service provider "warehouse" makes a labeller for "stock", once per journey
    Given a workflow "orders" with the steps:
      | step    | services        | outcome |
      | reserve | stock: labeller | success |
      | charge  | stock: labeller | success |
      | ship    | stock: labeller | success |
    And the workflow binds the service provider "stock"
    And the workflow binds the service provider "warehouse" to the steps "reserve", "ship"
    When the workflow runs
    Then the steps were given the services:
      | step    | service | label       | attempt |
      | reserve | stock   | warehouse 1 | 1       |
      | charge  | stock   | stock 1     | 1       |
      | ship    | stock   | warehouse 1 | 1       |
    And the service provider "warehouse" was called 1 times
    And the service provider "stock" was called 1 times

  Scenario: An attached provider needs no provider of the same key for the other steps
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
      | ship   |                    | success |
    And the workflow binds the service provider "payments" to the step "charge"
    When the workflow runs
    Then step "charge" was given the service "payments" labelled "payments 1" for attempt 1
    And the journey succeeded

  Scenario: The listing shows which provider serves each step's services
    Given the service provider "stock" makes a labeller for "stock", once per journey
    Given the service provider "payments" makes a labeller for "payments", once per journey
    Given the service provider "fresh stock" makes a labeller for "stock", for each attempt
    Given a workflow "orders" with the steps:
      | step    | services                            | outcome |
      | reserve | stock: labeller                     | success |
      | charge  | payments: labeller, stock: labeller | success |
      | ship    |                                     | success |
    And the workflow binds the service provider "stock"
    And the workflow binds the service provider "payments"
    And the workflow binds the service provider "fresh stock" to the step "charge"
    When the workflow is listed
    Then the listing is:
      | step    | position | policies | adapter | services                               |
      | reserve | 1        |          |         | stock: stock                           |
      | charge  | 2        |          |         | payments: payments, stock: fresh stock |
      | ship    | 3        |          |         |                                        |
    And no step ran

  Scenario: A provider attached to a step that does not request its key is never called
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the service provider "payments" to the step "charge"
    When the workflow runs
    Then the service provider "payments" was called 0 times
    And the journey succeeded

  Scenario: A provider of another type that serves no step is not checked against one
    Given the service provider "stock" makes a meter for "stock", once per journey
    Given the service provider "warehouse" makes a labeller for "stock", once per journey
    Given a workflow "orders" with the steps:
      | step    | services        | outcome |
      | reserve | stock: labeller | success |
    And the workflow binds the service provider "stock"
    And the workflow binds the service provider "warehouse" to the step "reserve"
    When the workflow runs
    Then step "reserve" was given the service "stock" labelled "warehouse 1" for attempt 1
    And the service provider "stock" was called 0 times
    And the journey succeeded
