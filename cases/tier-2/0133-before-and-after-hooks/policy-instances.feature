@tier-2 @proposal-0133
Feature: Policy instances for the step hooks
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): `before step` and `after step` use one instance of each step
  policy that defines either of them, built at the step's turn before `before
  step`, and used by no attempt; every attempt, the first included, gets new
  instances, as in tier 1. A step policy that defines neither is built only
  for each attempt. When building the step's instance fails, the journey is aborted with
  `policy could not be built`, naming the step and the policy, with no attempt.

  Scenario: A step policy with step hooks is built once for the step and once for each attempt
    Given the step policies and their hooks:
      | policy | hook           |
      | tx     | before step    |
      | tx     | after step     |
      | tx     | before attempt |
      | tx     | after attempt  |
    And a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    When the workflow runs
    Then the policy "tx" was built 3 times
    And the journey succeeded

  Scenario: A step policy without step hooks is built only for each attempt
    Given the step policies and their hooks:
      | policy | hook            |
      | tx     | before attempt  |
      | tx     | after attempt   |
      | audit  | on step success |
    And a workflow "orders" with the steps:
      | step   | policies  |
      | charge | tx, audit |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    When the workflow runs
    Then the policy "tx" was built 2 times
    And the policy "audit" was built 2 times
    And the journey succeeded

  Scenario: A step policy with step hooks that fails when built aborts the journey before the first attempt
    Given a step policy "broken" defines the hook "before step"
    And the policy "broken" fails when it is built
    And a workflow "orders" with the steps:
      | step   | policies |
      | charge |          |
      | ship   | broken   |
    And the workflow lists the reporters "trace"
    And step "charge" succeeds
    And step "ship" succeeds
    When the workflow runs
    Then the events include, in order:
      | event           | step   | attempt | policy | code                      |
      | step_succeeded  | charge | 1       |        |                           |
      | journey_aborted | ship   |         | broken | policy could not be built |
    And the reporter "trace" received the event "attempt_started" 1 times
    And the hook "before step" of policy "broken" was not called
    And step "ship" ended as aborted after 0 attempts
    And the journey was aborted with the abort reason "policy could not be built"
