@tier-1 @proposal-0003
Feature: What the rescue step receives
  Checks proposal 0003 (Rescue steps): besides its inputs, read from the data
  bag, a rescue step may request from the step it rescues what a step hook may:
  the failed attempt's contributions, its failure reason and its error, each
  required or optional, under the same rules.

  Scenario: The rescue step receives the failed attempt's contributions and failure reason
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    | message       | details      | contributes        |
      | 1       | failure | expired | token expired | {"since": 3} | {"account": "A-1"} |
      | 2       | success |         |               |              |                    |
    And step "charge_rescue" requests rescued step data "account" of type string
    And step "charge_rescue" requests the failure reason
    And step "charge_rescue" succeeds
    When the workflow runs
    Then step "charge_rescue" was built with rescued step data "account" = "A-1"
    And step "charge_rescue" received the failure reason with code "expired", message "token expired" and details {"since": 3}
    And the journey succeeded

  Scenario: The rescue step receives the error of an abnormal termination
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | message      |
      | 1       | error   | unauthorised |
      | 2       | success |              |
    And step "charge_rescue" requests the error
    And step "charge_rescue" succeeds
    When the workflow runs
    Then step "charge_rescue" received the error with the message "unauthorised"
    And the journey succeeded

  Scenario: The rescue step reads its inputs from the data bag
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the data bag contains:
      | key    | value |
      | client | "c-9" |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests input "client" of type string
    And step "charge_rescue" succeeds
    When the workflow runs
    Then step "charge_rescue" was built with input "client" = "c-9"
    And the journey succeeded

  Scenario: A required failure reason that does not exist aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | message      |
      | 1       | error   | unauthorised |
    And step "charge_rescue" requests the failure reason
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the result names the step "charge_rescue" as where the journey was aborted, with the abort reason "required data missing"
    And the events include, in order:
      | event           | step          | key            | code                  |
      | attempt_started | charge_rescue |                |                       |
      | journey_aborted | charge_rescue | failure reason | required data missing |
    And step "charge" ended as aborted

  Scenario: Optional data the failed attempt did not contribute is absent
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests optional rescued step data "account" of type string
    And step "charge_rescue" succeeds
    When the workflow runs
    Then step "charge_rescue" was built with rescued step data "account" absent
    And the events include, in order:
      | event                 | step          | key     |
      | attempt_started       | charge_rescue |         |
      | optional_input_absent | charge_rescue | account |
      | step_succeeded        | charge_rescue |         |
    And the journey succeeded
