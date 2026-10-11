@tier-1 @proposal-0095
Feature: Providers attached to steps
  Checks proposal 0095: a provider attached to steps serves only those steps,
  replacing for them the provider of the same key attached to no step, which
  serves every other step. A journey-scoped provider attached to steps makes one
  instance per journey, shared by those steps only. The listing shows which
  provider serves each step's services.

  Scenario: A provider attached to two steps serves them, and the other provider serves the rest
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
      | charge  |
      | refund  |
      | ship    |
    And step "reserve" requests the service "payments" of type labeller
    And step "reserve" succeeds
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And step "refund" requests the service "payments" of type labeller
    And step "refund" succeeds
    And step "ship" requests the service "payments" of type labeller
    And step "ship" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, once per journey
    And the workflow declares the service provider "fresh payments" for "payments" of type labeller, for each attempt
    And the service provider "fresh payments" serves only the steps "charge", "refund"
    When the workflow runs
    Then step "reserve" was given the service "payments" labelled "payments 1" for attempt 1
    And step "charge" was given the service "payments" labelled "fresh payments 1" for attempt 1
    And step "refund" was given the service "payments" labelled "fresh payments 2" for attempt 1
    And step "ship" was given the service "payments" labelled "payments 1" for attempt 1
    And the service provider "payments" was called 1 times
    And the service provider "fresh payments" was called 2 times
    And the events include, in order:
      | event            | step    | key      | provider       |
      | service_provided | reserve | payments | payments       |
      | service_provided | charge  | payments | fresh payments |
      | service_provided | refund  | payments | fresh payments |

  Scenario: A journey-scoped provider attached to steps is shared by those steps only
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
      | charge  |
      | ship    |
    And step "reserve" requests the service "stock" of type labeller
    And step "reserve" succeeds
    And step "charge" requests the service "stock" of type labeller
    And step "charge" succeeds
    And step "ship" requests the service "stock" of type labeller
    And step "ship" succeeds
    And the workflow declares the service provider "stock" for "stock" of type labeller, once per journey
    And the workflow declares the service provider "warehouse" for "stock" of type labeller, once per journey
    And the service provider "warehouse" serves only the steps "reserve", "ship"
    When the workflow runs
    Then step "reserve" was given the service "stock" labelled "warehouse 1" for attempt 1
    And step "charge" was given the service "stock" labelled "stock 1" for attempt 1
    And step "ship" was given the service "stock" labelled "warehouse 1" for attempt 1
    And the service provider "warehouse" was called 1 times
    And the service provider "stock" was called 1 times

  Scenario: An attached provider needs no provider of the same key for the other steps
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" requests the service "payments" of type labeller
    And step "charge" succeeds
    And step "ship" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" serves only the steps "charge"
    When the workflow runs
    Then step "charge" was given the service "payments" labelled "payments 1" for attempt 1
    And the journey succeeded

  Scenario: The listing shows which provider serves each step's services
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
      | charge  |
      | ship    |
    And step "reserve" requests the service "stock" of type labeller
    And step "reserve" succeeds
    And step "charge" requests the service "payments" of type labeller
    And step "charge" requests the service "stock" of type labeller
    And step "charge" succeeds
    And step "ship" succeeds
    And the workflow declares the service provider "stock" for "stock" of type labeller, once per journey
    And the workflow declares the service provider "payments" for "payments" of type labeller, once per journey
    And the workflow declares the service provider "fresh stock" for "stock" of type labeller, for each attempt
    And the service provider "fresh stock" serves only the steps "charge"
    When the workflow is listed
    Then the listing is:
      | step    | position | policies | adapter | services                               |
      | reserve | 1        |          |         | stock: stock                           |
      | charge  | 2        |          |         | payments: payments, stock: fresh stock |
      | ship    | 3        |          |         |                                        |
    And no step ran

  Scenario: A provider attached to a step that does not request its key is never called
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow declares the service provider "payments" for "payments" of type labeller, for each attempt
    And the service provider "payments" serves only the steps "charge"
    When the workflow runs
    Then the service provider "payments" was called 0 times
    And the journey succeeded

  Scenario: A provider of another type that serves no step is not checked against one
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
    And step "reserve" requests the service "stock" of type labeller
    And step "reserve" succeeds
    And the workflow declares the service provider "stock" for "stock" of type meter, once per journey
    And the workflow declares the service provider "warehouse" for "stock" of type labeller, once per journey
    And the service provider "warehouse" serves only the steps "reserve"
    When the workflow runs
    Then step "reserve" was given the service "stock" labelled "warehouse 1" for attempt 1
    And the service provider "stock" was called 0 times
    And the journey succeeded
