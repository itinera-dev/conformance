@tier-2 @proposal-0130
Feature: A dropped journey and on journey dropped
  Checks proposal 0130 (cancelling a journey): where a language lets a caller
  drop a running journey, the journey stops where it is: no further event is
  delivered and none of the hooks of proposal 0133 run. The one thing that
  runs is the workflow hook `on journey dropped`, once, called synchronously,
  and only for a journey dropped after `journey_started` and before its last
  event. It and every role operation it calls must be synchronous: an
  asynchronous one is the violation `asynchronous drop hook`. A language that
  cannot drop a running journey excludes the scenarios tagged
  `@dropped-journey` as impossible, with its proof.

  @dropped-journey @proposal-0133
  Scenario: A dropped journey runs on journey dropped once, and nothing else
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "tx" defines the hook "after step"
    And step "charge" has the policies "tx"
    And the workflow policies define the hooks:
      | policy | hook               | requests       |
      | guard  | on journey dropped | the journey ID |
      | guard  | after journey      |                |
    And the workflow has the policies "guard"
    And the workflow's ID generator returns "J-1"
    And the workflow lists the reporters "trace"
    And the caller drops the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was called 1 times
    And the hook "on journey dropped" of policy "guard" received the journey ID "J-1"
    And the hook "after step" of policy "tx" was not called
    And the hook "after journey" of policy "guard" was not called
    And the reporter "trace" did not receive the event "journey_cancelled"
    And the last event is "step_succeeded"

  @dropped-journey
  Scenario: On journey dropped calls a role of the workflow
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow provides the role "alerts" with the operation "page"
    And a workflow policy "guard" defines the hook "on journey dropped"
    And the hook "on journey dropped" of policy "guard" requests the role "alerts" and calls its operation "page"
    And the workflow has the policies "guard"
    And the caller drops the journey on "attempt_started" of "charge"
    When the workflow runs
    Then the operation "page" of the role "alerts" was called 1 times

  Scenario: On journey dropped does not run when the journey succeeds
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | success | declined |
    And a workflow policy "guard" defines the hook "on journey dropped"
    And the workflow has the policies "guard"
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was not called

  Scenario: On journey dropped does not run when the journey fails
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And a workflow policy "guard" defines the hook "on journey dropped"
    And the workflow has the policies "guard"
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was not called

  Scenario: On journey dropped does not run when the journey is aborted
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    And a workflow policy "guard" defines the hook "on journey dropped"
    And the workflow has the policies "guard"
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was not called
    And the journey was aborted with the abort reason "required data missing"

  Scenario: On journey dropped does not run when the journey is cancelled
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "guard" defines the hook "on journey dropped"
    And the workflow has the policies "guard"
    And the caller cancels the journey on "step_succeeded" of "charge"
    When the workflow runs
    Then the hook "on journey dropped" of policy "guard" was not called
    And the run ended as cancelled

  Scenario: On journey dropped is defined at most once per workflow
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow policies define the hooks:
      | policy | hook               |
      | guard  | on journey dropped |
      | alarm  | on journey dropped |
    And the workflow has the policies "guard", "alarm"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation          |
      | hook defined twice |

  @asynchronous-drop-hook
  Scenario: An asynchronous on journey dropped is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "guard" defines the hook "on journey dropped"
    And the hook "on journey dropped" of policy "guard" is asynchronous
    And the workflow has the policies "guard"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation              |
      | asynchronous drop hook |

  @asynchronous-drop-hook
  Scenario: An asynchronous role operation called by on journey dropped is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow provides the role "alerts" with the operation "page"
    And the operation "page" of the role "alerts" is asynchronous
    And a workflow policy "guard" defines the hook "on journey dropped"
    And the hook "on journey dropped" of policy "guard" requests the role "alerts" and calls its operation "page"
    And the workflow has the policies "guard"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation              |
      | asynchronous drop hook |
