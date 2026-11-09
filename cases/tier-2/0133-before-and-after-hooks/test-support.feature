@tier-2 @proposal-0133 @capability-testing
Feature: Hooks before and after in test support
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt) with proposal 0108 (Test support): the recording reporter assembles
  each line of the path from the fields of its event. The path gains `<step>
  bypassed`, followed by `: <reason>` when it has one; `<step> attempt <n>
  before hook failed: <error>` and `<step> attempt <n> after hook failed:
  <error>`, without `attempt <n>` at the step level and as `journey before hook
  failed: <error>` and `journey after hook failed: <error>` at the journey
  level; the causes `before hook failed` and `after hook failed` for `<step>
  given up`; and `journey failed: <reason>` when `journey_failed` names no step.

  Scenario: The path of a bypassed step, with and without a reason
    Given a workflow "orders" with the steps:
      | step     |
      | discount |
      | gift     |
      | ship     |
    And step "discount" succeeds
    And step "gift" succeeds
    And step "ship" succeeds
    And the step policies define the hooks:
      | policy | hook        | returns | code              |
      | gate   | before step | bypass  | no discount today |
      | wrap   | before step | bypass  |                   |
    And step "discount" has the policies "gate"
    And step "gift" has the policies "wrap"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                 |
      | discount bypassed: no discount today |
      | gift bypassed                        |
      | ship attempt 1 succeeded             |
      | journey succeeded                    |

  Scenario: The path of a failing before step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "lock" defines the hook "before step"
    And the hook "before step" of policy "lock" fails with "no lock"
    And step "charge" has the policies "lock"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                |
      | charge before hook failed: no lock  |
      | charge given up: before hook failed |
      | journey failed at charge: no lock   |

  Scenario: The path of a failing before attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "tx" defines the hook "before attempt"
    And the hook "before attempt" of policy "tx" fails with "no connection"
    And step "charge" has the policies "tx"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                               |
      | charge attempt 1 before hook failed: no connection |
      | charge given up: before hook failed                |
      | journey failed at charge: no connection            |

  Scenario: The path of a failing after attempt after a success
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" fails with "commit failed"
    And step "charge" has the policies "tx"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                              |
      | charge attempt 1 succeeded                        |
      | charge attempt 1 after hook failed: commit failed |
      | charge given up: after hook failed                |
      | journey failed at charge: commit failed           |

  Scenario: The path of a failing after step after a success
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "tx" defines the hook "after step"
    And the hook "after step" of policy "tx" fails with "settle failed"
    And step "charge" has the policies "tx"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                    |
      | charge attempt 1 succeeded              |
      | charge after hook failed: settle failed |
      | charge given up: after hook failed      |
      | journey failed at charge: settle failed |

  Scenario: The path of a journey failed by before journey, which names no step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "check" defines the hook "before journey"
    And the hook "before journey" of policy "check" returns FailWorkflow with code "bad input"
    And the workflow has the policies "check"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                      |
      | journey failed: bad input |

  Scenario: The path of a failing before journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "check" defines the hook "before journey"
    And the hook "before journey" of policy "check" fails with "rules unavailable"
    And the workflow has the policies "check"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                          |
      | journey before hook failed: rules unavailable |
      | journey aborted: hook failed                  |

  Scenario: The path of a failing after journey after a success
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "audit" defines the hook "after journey"
    And the hook "after journey" of policy "audit" fails with "audit down"
    And the workflow has the policies "audit"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                  |
      | charge attempt 1 succeeded            |
      | journey after hook failed: audit down |
      | journey failed: audit down            |
