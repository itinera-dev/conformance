@tier-1 @proposal-0012
Feature: The local executor
  Checks proposal 0012: run returns a result instead of throwing, an executor is
  stateless between journeys and leaks nothing through its dispatcher, and an
  executor refuses execution modes it does not accept. Running an instance twice
  and calling run concurrently are checked by each language's own tests, since
  many languages, Rust among them, make both impossible to write.

  Scenario: run returns the result of a failed journey instead of throwing
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then run returned a result instead of throwing
    And the journey failed

  Scenario: run returns the result of an aborted journey instead of throwing
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" cannot be built because its constructor fails with "no connection"
    When the workflow runs
    Then run returned a result instead of throwing
    And the journey was aborted

  Scenario: An executor is stateless between journeys
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    When the same executor runs the workflow twice, with a new instance each time
    Then the two journeys have different journey IDs
    And the second journey's events are the first journey's events, apart from the journey ID and timestamps

  Scenario: A dispatcher given to the executor leaks no reporter from one journey to the next
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit"
    And the executor is given a dispatcher holding the reporter "test"
    When the same executor runs the workflow twice, with a new instance each time
    Then each instance's reporter "audit" received only its own journey's events

  @capability-sync @proposal-0042 @mode-not-accepted
  Scenario: A synchronous-only executor refuses an asynchronous step before the journey starts
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" is asynchronous
    And step "charge" succeeds
    And the executor accepts only synchronous steps, hooks and reporters
    When the workflow runs
    Then admission is refused with the violations:
      | violation         |
      | mode not accepted |
    And no event was emitted
