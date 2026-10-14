@tier-1 @proposal-0108 @capability-testing
Feature: A scripted run plays what the script says instead of running steps
  Checks proposal 0108 (Test support): in a scripted run every step is still
  built for real, and only the call to its run is replaced for the attempts the
  script describes. A step the script does not name, and an attempt scripted to
  run for real, run the real step. A scripted ending has the consequences of
  the outcome it stands for, and what a scripted attempt contributes, emits and
  sets happens as if the step had done it.

  Scenario: A scripted attempt replaces the step's run
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" contributes "real" = true
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | 1       | failure | declined |
    When the workflow runs with the script
    Then the journey failed
    And the result names the failed step "charge" with the code "declined"
    And no contribution of "real" was committed

  Scenario: A step the script does not name runs for real
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" contributes "shipped" = true
    And step "ship" succeeds
    And the script says:
      | step   | attempt | ending  |
      | charge | 1       | success |
    When the workflow runs with the script
    Then the journey succeeded
    And the result's data bag contains:
      | key     | value |
      | shipped | true  |

  Scenario: An attempt scripted to run for real runs the real step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" contributes "real" = true
    And step "charge" succeeds
    And step "charge" allows 1 retries
    And the script says:
      | step   | attempt | ending   | code     |
      | charge | 1       | failure  | declined |
      | charge | 2       | real run |          |
    When the workflow runs with the script
    Then the journey succeeded
    And step "charge" ended as succeeded after 2 attempts
    And the result's data bag contains:
      | key  | value |
      | real | true  |

  Scenario: A scripted step is still built, so a missing required input aborts the journey
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
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "required data missing"

  Scenario: A scripted step is still built, so a failing constructor aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" cannot be built because its constructor fails with "broken"
    And the script says:
      | step   | attempt | ending  |
      | charge | 1       | success |
    When the workflow runs with the script
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "step could not be built"
    And the result's abort carries the error "broken"

  Scenario: A scripted step is still built, so a failing service provider aborts the journey
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
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "step could not be built"
    And the result's abort carries the error "gateway down"

  Scenario: A scripted skip is a skip, with its reason
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | code |
      | charge | 1       | skipped | paid |
    When the workflow runs with the script
    Then the events include, in order:
      | event        | step   | attempt | code |
      | step_skipped | charge | 1       | paid |
    And step "charge" ended as skipped after 1 attempts

  Scenario: A scripted skip without a reason is a skip without one
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  |
      | charge | 1       | skipped |
    When the workflow runs with the script
    Then the events include, in order:
      | event        | step   | attempt | code |
      | step_skipped | charge | 1       |      |
    And step "charge" ended as skipped after 1 attempts

  Scenario: A scripted abnormal termination is retried within the budget, as an error escaping the step would be
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And step "charge" allows 1 retries
    And the script says:
      | step   | attempt | ending               | message |
      | charge | 1       | abnormal termination | timeout |
      | charge | 2       | success              |         |
    When the workflow runs with the script
    Then the events include, in order:
      | event                     | step   | attempt | cause                |
      | step_abnormal_termination | charge | 1       |                      |
      | step_retrying             | charge | 1       | abnormal termination |
      | step_succeeded            | charge | 2       |                      |
    And the journey succeeded

  Scenario: Scripted contributions are committed only when the attempt succeeds
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And step "charge" allows 1 retries
    And the workflow lists the reporters "audit"
    And the script says:
      | step   | attempt | contributes    | ending  | code     |
      | charge | 1       | {"charged": 1} | failure | declined |
      | charge | 2       | {"charged": 2} | success |          |
    When the workflow runs with the script
    Then the reporter "audit" received the event "contribution_committed" 1 times
    And the result's data bag contains:
      | key     | value |
      | charged | 2     |

  Scenario: Scripted emits and global metadata are the step's own
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit"
    And the script says:
      | step   | attempt | emits        | emit message | sets global metadata | ending  |
      | charge | 1       | step_warning | low stock    | {"user_id": "u-7"}   | success |
    When the workflow runs with the script
    Then the events include, in order:
      | event               | step   | attempt | message   | key     | source |
      | attempt_started     | charge | 1       |           |         |        |
      | step_warning        | charge | 1       | low stock |         |        |
      | global_metadata_set | charge | 1       |           | user_id | charge |
      | step_succeeded      | charge | 1       |           |         |        |
    And the reporter "audit" received the global metadata:
      | key        | value | after        |
      | journey_id |       | none         |
      | user_id    | "u-7" | step_warning |

  Scenario: A scripted rescue step rescues its step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And the script says:
      | step          | attempt | ending  | code    |
      | charge        | 1       | failure | expired |
      | charge        | 2       | success |         |
      | charge_rescue | 1       | success |         |
    When the workflow runs with the script
    Then the events include, in order:
      | event          | step          | attempt | rescue        |
      | step_rescuing  | charge        | 1       | charge_rescue |
      | step_succeeded | charge_rescue | 1       |               |
      | step_rescued   | charge        | 1       | charge_rescue |
      | step_succeeded | charge        | 2       |               |
    And the journey succeeded
