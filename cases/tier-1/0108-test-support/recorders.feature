@tier-1 @proposal-0108 @capability-testing
Feature: Recorders lend a step, a hook or an input adapter its handles outside a journey
  Checks proposal 0108 (Test support): a test calls a step's run, a hook or an
  input adapter itself, with handles lent by recorders, and reads back what was
  contributed and emitted. A lent handle behaves as in a journey: a failing
  recorder interrupts every call and keeps nothing, and setting journey_id
  interrupts that call and every later one.

  Scenario: The contributions recorder keeps what a step contributes
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" contributes "charged" = 40
    And step "charge" contributes "currency" = "EUR"
    And step "charge" succeeds
    When step "charge" runs alone
    Then the contributions recorder holds:
      | key      | value |
      | charged  | 40    |
      | currency | "EUR" |

  Scenario: The step event reporter keeps the events and the global metadata a step sets
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" emits step_info "charging" with data {"amount": 40}
    And step "charge" sets the global metadata "user_id" to "u-7"
    And step "charge" emits step_warning "slow gateway"
    And step "charge" succeeds
    When step "charge" runs alone
    Then the step event reporter kept the events:
      | level   | message      | data           |
      | info    | charging     | {"amount": 40} |
      | warning | slow gateway | none           |
    And the step event reporter kept the global metadata:
      | key     | value |
      | user_id | "u-7" |

  Scenario: A failing step event reporter interrupts every call and keeps nothing
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" emits step_info "charging"
    And step "charge" sets the global metadata "user_id" to "u-7"
    And step "charge" succeeds
    And the step event reporter is failing
    When step "charge" runs alone
    Then every call step "charge" made to its step reporter was interrupted
    And the step event reporter kept nothing

  Scenario: Setting journey_id interrupts that call and every later one
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" emits step_info "before"
    And step "charge" sets the global metadata "journey_id" to "other"
    And step "charge" emits step_info "after"
    And step "charge" succeeds
    When step "charge" runs alone
    Then the call step "charge" made setting "journey_id", and every call after it, was interrupted, and no call before it
    And the step event reporter kept the events:
      | level | message |
      | info  | before  |

  Scenario: The hook event reporter keeps the events a hook emits, and the contributions recorder what it contributes
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" emits journey_info "seen"
    And the hook "on step success" of policy "audit" contributes "seen" = true
    And step "charge" has the policies "audit"
    When the hook "on step success" of policy "audit" runs alone
    Then the hook event reporter kept the events:
      | level | message |
      | info  | seen    |
    And the contributions recorder holds:
      | key  | value |
      | seen | true  |

  Scenario: A failing hook event reporter interrupts every call and keeps nothing
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" emits journey_info "seen"
    And step "charge" has the policies "audit"
    And the hook event reporter is failing
    When the hook "on step success" of policy "audit" runs alone
    Then every call the hook "on step success" of policy "audit" made to its hook reporter was interrupted
    And the hook event reporter kept nothing

  Scenario: A data bag built from values lends an input adapter its read access
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the workflow declares the input adapter "amounts" for the steps "charge"
    And the input adapter "amounts" requests the data bag
    And the input adapter "amounts" returns "total" of type integer, read from the data bag, for "amount"
    When the input adapter "amounts" is called alone for the input "amount" of step "charge", with a data bag holding:
      | key   | value |
      | total | 40    |
    Then the input adapter returned 40
