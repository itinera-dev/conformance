@tier-2 @proposal-0133
Feature: Declaring before and after hooks
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): any number of the policies attached to a step, or to a workflow,
  may define each of the six hooks, so `hook defined twice` does not apply to
  them, while it still applies to the hooks of tier 1. Every request of an
  after hook must be optional, except the journey ID, roles, the means of
  emitting, the step's name, the attempt number, the ending and the number of
  attempts, which always exist; a required one is the violation `required
  request in after hook`, found when the workflow is built.

  Scenario: Several policies of one step and of the workflow may define the same before and after hooks
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the step policies define the hooks:
      | policy | hook          |
      | tx     | before step   |
      | tx     | after attempt |
      | lock   | before step   |
      | lock   | after attempt |
    And step "charge" has the policies "tx", "lock"
    And the workflow policies define the hooks:
      | policy | hook          |
      | audit  | after journey |
      | trace  | after journey |
    And the workflow has the policies "audit", "trace"
    When the workflow runs
    Then the journey succeeded

  Scenario: Hook defined twice still applies to the hooks of tier 1 beside the new ones
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the step policies define the hooks:
      | policy | hook            |
      | tx     | after step      |
      | tx     | on step success |
      | lock   | after step      |
      | lock   | on step success |
    And step "charge" has the policies "tx", "lock"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation          |
      | hook defined twice |

  Scenario: A required request for step data in after attempt is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" requests step data "receipt" of type string
    And step "charge" has the policies "tx"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation                      |
      | required request in after hook |
    And no journey ID was produced

  Scenario: A required request for data from the workflow in after journey is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "audit" defines the hook "after journey"
    And the hook "after journey" of policy "audit" requests data from the workflow "order" of type string
    And the workflow has the policies "audit"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation                      |
      | required request in after hook |

  Scenario: A required request for the failure reason in after step is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "tx" defines the hook "after step"
    And the hook "after step" of policy "tx" requests the failure reason
    And step "charge" has the policies "tx"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation                      |
      | required request in after hook |

  Scenario: After hooks may require what always exists
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the step policies define the hooks:
      | policy | hook          | requests                                                      |
      | tx     | after attempt | the step name, the attempt number, the ending, the journey ID |
      | tx     | after step    | the number of attempts                                        |
    And step "charge" has the policies "tx"
    And the workflow's ID generator returns "J-1"
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received the step name "charge"
    And the hook "after attempt" of policy "tx" received the attempt number 1
    And the hook "after attempt" of policy "tx" received the journey ID "J-1"
    And the hook "after attempt" of policy "tx" received the endings "succeeded"
    And the hook "after step" of policy "tx" received the number of attempts 1
    And the journey succeeded

  Scenario: Before hooks may require data from the workflow, and a missing one aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the data bag is empty
    And the step policies define the hooks:
      | policy | hook           |
      | tx     | before attempt |
      | tx     | after attempt  |
    And the hook "before attempt" of policy "tx" requests data from the workflow "order" of type string
    And step "charge" has the policies "tx"
    When the workflow runs
    Then the events include, in order:
      | event           | step   | policy | hook           | key   | code                  |
      | journey_aborted | charge | tx     | before attempt | order | required data missing |
    And the hook "after attempt" of policy "tx" was called 1 times
    And the journey was aborted with the abort reason "required data missing"
