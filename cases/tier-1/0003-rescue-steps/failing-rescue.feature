@tier-1 @proposal-0003
Feature: A rescue step that does not succeed
  Checks proposal 0003 (Rescue steps): a rescue step that fails, or ends in an
  abnormal termination, is a step that failed, so the journey fails because of
  it and the rescued step never runs again. A rescue step must not skip: a skip
  aborts the journey with `rescue skipped`. An abort while the rescue step runs
  names the rescue step.

  Scenario: A rescue step that fails fails the journey, and the step does not run again
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | code       |
      | 1       | failure | no-refresh |
    And step "ship" succeeds
    And a step policy "alarm" defines the hook "on step failure"
    And step "charge" has the policies "alarm"
    And a workflow policy "report" defines the hook "on workflow failure"
    And the workflow has the policies "report"
    When the workflow runs
    Then the events are exactly:
      | event           | step          | attempt | code       | policy | hook                | cause   | rescue        | decided by |
      | journey_started |               |         |            |        |                     |         |               |            |
      | attempt_started | charge        | 1       |            |        |                     |         |               |            |
      | step_failed     | charge        | 1       | expired    |        |                     |         |               |            |
      | step_rescuing   | charge        | 1       |            |        |                     | failure | charge_rescue | default    |
      | attempt_started | charge_rescue | 1       |            |        |                     |         |               |            |
      | step_failed     | charge_rescue | 1       | no-refresh |        |                     |         |               |            |
      | step_given_up   | charge_rescue | 1       |            |        |                     | failure |               | default    |
      | hook_called     |               |         |            | report | on workflow failure |         |               |            |
      | journey_failed  | charge_rescue |         | no-refresh |        |                     | failure |               | default    |
    And the hook "on step failure" of policy "alarm" was not called
    And step "charge" ended as rescuing after 1 attempts
    And step "charge_rescue" ended as failed after 1 attempts
    And step "ship" ended as not executed after 0 attempts
    And the result names the failed step "charge_rescue" with the code "no-refresh"

  @proposal-0083
  Scenario: A rescue step that ends in an abnormal termination fails the journey with its error
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | message      |
      | 1       | error   | refresh down |
    When the workflow runs
    Then the events include, in order:
      | event                     | step          | attempt | cause                | error        |
      | step_abnormal_termination | charge_rescue | 1       |                      |              |
      | step_given_up             | charge_rescue | 1       | abnormal termination |              |
      | journey_failed            | charge_rescue |         | abnormal termination | refresh down |
    And the result's failure has the cause "abnormal termination"
    And the result's failure carries the error "refresh down"
    And step "charge" ended as rescuing after 1 attempts
    And the journey failed

  @rescue-skip
  Scenario: A rescue step that skips aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" attempts:
      | attempt | outcome | contributes      |
      | 1       | skipped | {"token": "new"} |
    When the workflow runs
    Then the events include, in order:
      | event                   | step          | attempt | code           |
      | step_skipped            | charge_rescue | 1       |                |
      | contributions_discarded | charge_rescue | 1       |                |
      | journey_aborted         | charge_rescue |         | rescue skipped |
    And the last event is "journey_aborted"
    And no contribution of "token" was committed
    And the result names the step "charge_rescue" as where the journey was aborted, with the abort reason "rescue skipped"
    And step "charge_rescue" ended as skipped after 1 attempts
    And step "charge" ended as aborted

  @proposal-0083
  Scenario: An abort while the rescue step is built names the rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" cannot be built because its constructor fails with "no client"
    When the workflow runs
    Then the result names the step "charge_rescue" as where the journey was aborted, with the abort reason "step could not be built"
    And the result's abort carries the error "no client"
    And step "charge_rescue" ended as aborted
    And step "charge" ended as aborted

  @proposal-0055
  Scenario: An abort while the rescue step runs names the rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow lists the reporters "audit", "fragile"
    And the executor uses its default dispatcher
    And the reporter "fragile" throws on "step_info"
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "charge_rescue" emits step_info "refreshing"
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the result names the step "charge_rescue" as where the journey was aborted, with the abort reason "reporter failed"
    And the reporter "audit" did not receive the event "step_rescued"
    And step "charge_rescue" ended as aborted after 1 attempts
    And step "charge" ended as aborted
    And the last event is "journey_aborted"
