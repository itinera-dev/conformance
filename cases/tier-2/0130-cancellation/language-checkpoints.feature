@tier-2 @proposal-0130 @language-checkpoint
Feature: A cancellation delivered inside custom code
  Checks proposal 0130 (cancelling a journey): where a language delivers
  cancellation to running custom code as a failure, that failure is the
  cancellation, whatever the custom code is: not an abnormal termination, an
  abort or `hook failed`. The call ends, the journey is cancelled at a
  language checkpoint, nothing is retried or rescued, and an attempt it ends
  has no outcome fact and no step decision. It counts as the cancellation only
  when the journey's token was triggered before the failure; otherwise it is an
  ordinary failure. A language that has no language checkpoints excludes these
  scenarios, saying so in its tech spec.

  @proposal-0133
  Scenario: A cancellation delivered inside a step ends its attempt with no outcome fact
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" allows 2 retries
    And step "charge" has a rescue step
    And step "charge" emits step_info "calling the bank"
    And step "charge" waits for cancellation
    And step "charge_rescue" succeeds
    And its step policies and their hooks are:
      | policy | hook                         | requests |
      | tx     | after attempt                | ending   |
      | tx     | on step abnormal termination |          |
    And the workflow lists the reporters "trace"
    And the caller cancels the journey on "step_info" of "charge"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | policy | hook          | checkpoint          |
      | step_info         | charge | 1       |        |               |                     |
      | hook_called       | charge | 1       | tx     | after attempt |                     |
      | journey_cancelled | charge | 1       |        |               | language checkpoint |
    And the reporter "trace" did not receive the event "step_abnormal_termination"
    And the reporter "trace" did not receive the event "step_rescuing"
    And the reporter "trace" did not receive the event "journey_aborted"
    And the hook "on step abnormal termination" of policy "tx" was not called
    And the hook "after attempt" of policy "tx" received the endings "cancelled"
    And step "charge" ended as abandoned after 1 attempts
    And the run ended as cancelled

  Scenario: A cancellation delivered inside a service provider cancels the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests the service "labels" of type labeller
    And step "charge" succeeds
    And the workflow declares the service provider "stock" for "labels" of type labeller, for each attempt
    And the service provider "stock" emits journey_info "reserving"
    And the service provider "stock" waits for cancellation
    And the workflow lists the reporters "trace"
    And the caller cancels the journey on "journey_info"
    When the workflow runs
    Then the events include, in order:
      | event             | step   | attempt | checkpoint          |
      | journey_info      |        |         |                     |
      | journey_cancelled | charge | 1       | language checkpoint |
    And the reporter "trace" did not receive the event "service_provider_failed"
    And the reporter "trace" did not receive the event "journey_aborted"
    And the run ended as cancelled

  Scenario: A cancellation delivered inside a hook is not hook failed
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | notify   |
    And step "charge" succeeds
    And a step policy "notify" defines the hook "on step success"
    And the hook "on step success" of policy "notify" emits journey_info "sending"
    And the hook "on step success" of policy "notify" waits for cancellation
    And the workflow lists the reporters "trace"
    And the caller cancels the journey on "journey_info"
    When the workflow runs
    Then the events include, in order:
      | event             | checkpoint          |
      | journey_info      |                     |
      | journey_cancelled | language checkpoint |
    And the reporter "trace" did not receive the event "journey_aborted"
    And the run ended as cancelled

  @proposal-0133
  Scenario: A cancellation delivered inside an after hook during the normal flow runs the rest of its level in cleanup
    Given a workflow "orders" with the steps:
      | step   | policies  |
      | charge | tx, audit |
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook          | requests |
      | tx     | after attempt |          |
      | tx     | after step    | ending   |
      | audit  | after attempt |          |
    And the hook "after attempt" of policy "audit" emits journey_info "auditing"
    And the hook "after attempt" of policy "audit" waits for cancellation
    And the caller cancels the journey on "journey_info"
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook          |
      | audit  | after attempt |
      | tx     | after attempt |
      | tx     | after step    |
    And the hook "after step" of policy "tx" received the endings "cancelled"
    And the run ended as cancelled

  Scenario: The language's cancellation failure without a triggered token is an ordinary abnormal termination
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" fails with the language's cancellation failure
    When the workflow runs
    Then the events include, in order:
      | event                     | step   | attempt | cause                |
      | step_abnormal_termination | charge | 1       |                      |
      | step_given_up             | charge | 1       | abnormal termination |
      | journey_failed            | charge |         |                      |
    And the journey failed
