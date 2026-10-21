@tier-1 @proposal-0108 @capability-testing
Feature: A script is checked before the journey
  Checks proposal 0108 (Test support): before the journey starts, a scripted
  run stops the test when the script leaves out an attempt a scripted step can
  have, the rescue step of a scripted step that can fail on attempt 1, or, when
  the test asks for every step, a step; and a mistake in writing the script
  stops the test where it is written. Either way the report names each
  problem, and no journey starts.
  Proposal 0119, which amends proposal 0108: choosing an attempt the script
  has already described is "attempt scripted twice", and one the step can
  never have is "no such attempt", which is named rather than "attempt
  scripted twice" or "gap in the attempts" when a choice is both.

  Scenario: Describing every attempt the retry budget allows is enough
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | every   | failure | declined |
    When the workflow runs with the script
    Then step "charge" ended as failed after 3 attempts

  Scenario: The remaining attempts can be described at once
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And the script says:
      | step   | attempt   | ending  | code     |
      | charge | 1         | failure | declined |
      | charge | remaining | success |          |
    When the workflow runs with the script
    Then step "charge" ended as succeeded after 2 attempts

  Scenario: No attempt is needed after one that cannot be followed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" allows 2 retries
    And step "charge" does not retry abnormal terminations
    And step "ship" allows 2 retries
    And step "ship" succeeds
    And the script says:
      | step   | attempt | ending               | message |
      | charge | 1       | abnormal termination | timeout |
      | ship   | 1       | success              |         |
    When the workflow runs with the script
    Then step "charge" ended as failed after 1 attempts

  Scenario: A script that leaves out an attempt or a rescue step stops the test, naming each
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And step "ship" allows 1 retries
    And step "ship" succeeds
    And the script says:
      | step   | attempt | ending  | code    |
      | charge | 1       | failure | expired |
      | ship   | 1       | failure | closed  |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake              | step          | attempt |
      | attempt left out     | charge        | 2       |
      | rescue step left out | charge_rescue |         |
      | attempt left out     | ship          | 2       |
    And no event was emitted

  Scenario: A test that asks for every step to be scripted stops when one is not
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And the script says:
      | step   | attempt | ending  |
      | charge | 1       | success |
    And the script ensures every step is scripted
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake       | step |
      | step left out | ship |
    And no event was emitted

  Scenario: A script that names a step the workflow does not have stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  |
      | refund | 1       | success |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake      | step   |
      | unknown step | refund |
    And no event was emitted

  Scenario: A script that names a step twice stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And step "ship" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | 1       | failure | declined |
      | ship   | 1       | success |          |
      | charge | 2       | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake             | step   |
      | step scripted twice | charge |
    And no event was emitted

  Scenario: A script with a gap in a step's attempts stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | 1       | failure | declined |
      | charge | 3       | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake             | step   | attempt |
      | gap in the attempts | charge | 3       |
    And no event was emitted

  Scenario: A script that makes a rescue step skip stops the test
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
      | charge_rescue | 1       | skipped |         |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake           | step          |
      | rescue step skips | charge_rescue |
    And no event was emitted

  @undeclared-handles
  Scenario: A script that contributes for a step that declares no contributor stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" declares no contributor and no reporter
    And step "charge" succeeds
    And the script says:
      | step   | attempt | contributes    | ending  |
      | charge | 1       | {"charged": 1} | success |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake        | step   |
      | no contributor | charge |
    And no event was emitted

  @undeclared-handles
  Scenario: A script that emits for a step that declares no reporter stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" declares no contributor and no reporter
    And step "charge" succeeds
    And the script says:
      | step   | attempt | emits     | emit message | ending  |
      | charge | 1       | step_info | charging     | success |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake     | step   |
      | no reporter | charge |
    And no event was emitted

  @undeclared-handles
  Scenario: A script that sets global metadata for a step that declares no reporter stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" declares no contributor and no reporter
    And step "charge" succeeds
    And the script says:
      | step   | attempt | sets global metadata | ending  |
      | charge | 1       | {"user_id": "u-7"}   | success |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake     | step   |
      | no reporter | charge |
    And no event was emitted

  @proposal-0119
  Scenario: A script that describes an attempt twice stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | 1       | failure | declined |
      | charge | 1       | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake                | step   | attempt |
      | attempt scripted twice | charge | 1       |
    And no event was emitted

  @proposal-0119
  Scenario: Every attempt chosen after a numbered one describes attempt 1 again
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | 1       | failure | declined |
      | charge | every   | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake                | step   | attempt |
      | attempt scripted twice | charge | 1       |
    And no event was emitted

  @proposal-0119
  Scenario: A numbered attempt chosen after every attempt describes it again
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | every   | failure | declined |
      | charge | 2       | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake                | step   | attempt |
      | attempt scripted twice | charge | 2       |
    And no event was emitted

  @proposal-0119
  Scenario: The remaining attempts chosen twice describe the first of them again
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt   | ending  | code     |
      | charge | 1         | failure | declined |
      | charge | remaining | failure | declined |
      | charge | remaining | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake                | step   | attempt |
      | attempt scripted twice | charge | 2       |
    And no event was emitted

  @proposal-0119 @attempt-zero
  Scenario: A script that describes attempt 0 stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  |
      | charge | 0       | success |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step   | attempt |
      | no such attempt | charge | 0       |
    And no event was emitted

  @proposal-0119 @attempt-negative
  Scenario: A script that describes a negative attempt stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  |
      | charge | -1      | success |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step   | attempt |
      | no such attempt | charge | -1      |
    And no event was emitted

  @proposal-0119 @attempt-fraction
  Scenario: A script that describes a fraction of an attempt stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  |
      | charge | 1.5     | success |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step   | attempt |
      | no such attempt | charge | 1.5     |
    And no event was emitted

  @proposal-0119
  Scenario: A script that describes an attempt past the retry budget stops the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | 1       | failure | declined |
      | charge | 2       | failure | declined |
      | charge | 3       | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step   | attempt |
      | no such attempt | charge | 3       |
    And no event was emitted

  @proposal-0119
  Scenario: A step with a rescue step can have no third attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | 1       | failure | expired  |
      | charge | 2       | failure | declined |
      | charge | 3       | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step   | attempt |
      | no such attempt | charge | 3       |
    And no event was emitted

  @proposal-0119
  Scenario: A rescue step can have no second attempt
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
      | charge_rescue | 1       | failure | broken  |
      | charge_rescue | 2       | success |         |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step          | attempt |
      | no such attempt | charge_rescue | 2       |
    And no event was emitted

  @proposal-0119
  Scenario: The remaining attempts of a step whose every attempt is described stop the test
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt   | ending  | code     |
      | charge | 1         | failure | declined |
      | charge | 2         | failure | declined |
      | charge | remaining | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step   | attempt |
      | no such attempt | charge | 3       |
    And no event was emitted

  @proposal-0119
  Scenario: An attempt the step can never have is named rather than a gap before it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  |
      | charge | 5       | success |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step   | attempt |
      | no such attempt | charge | 5       |
    And no event was emitted

  @proposal-0119
  Scenario: An attempt the step can never have is named rather than one described already
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt | ending  | code     |
      | charge | every   | failure | declined |
      | charge | 5       | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake         | step   | attempt |
      | no such attempt | charge | 5       |
    And no event was emitted

  @proposal-0119
  Scenario: A numbered attempt chosen after the remaining attempts describes it again
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" succeeds
    And the script says:
      | step   | attempt   | ending  | code     |
      | charge | 1         | failure | declined |
      | charge | remaining | failure | declined |
      | charge | 3         | success |          |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake                | step   | attempt |
      | attempt scripted twice | charge | 3       |
    And no event was emitted
