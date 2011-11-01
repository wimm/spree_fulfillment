Shipment.class_eval do
  
  # We can get infinite recursion if these options are applied more than once.  So ensure
  # we are the one and only one.
  raise "can't patch more than once" if defined?(self.sf_ensure_only_once)
  def self.sf_ensure_only_once
  end
  
  scope :fulfilling, where(:state => 'fulfilling')
  scope :fulfill_failed, where(:state => 'fulfill_fail')
  
  state_machines[:state] = nil    # reset original state machine to start from scratch.

  # We know that there will be preexisting methods from the original Spree state machine.
  # Until there's a better API to update a state machine, just ignore the conflicts by
  # overriding the old ones.  Ideally the state_machine gem would provide a way to delete
  # an existing machine.
  StateMachine::Machine.ignore_method_conflicts = true

  # This is a modified version of the original spree shipment state machine
  # with the indicated changes.
  state_machine :initial => 'pending', :use_transactions => false do
    event :ready do
      transition :from => 'pending', :to => 'ready'
    end
    event :pend do
      transition :from => 'ready', :to => 'pending'
    end
    event :ship do
      transition :from => 'ready', :to => 'fulfilling'                # was 'shipped'
    end
    event :ship_from_warehouse do                                     # new event
      transition :from => 'fulfilling', :to => 'shipped'
    end
    event :fail_at_warehouse do                                       # new event
      transition :from => 'fulfilling', :to => 'fulfill_fail'
    end
    before_transition :to => 'fulfilling', :do => :before_fulfilling  # new callback
    after_transition :to => 'shipped', :do => :after_ship
  end


  # If there's an error submitting to the fulfillment service, we should halt
  # the transition to 'fulfill' and stay in 'ready'.  That way transient errors
  # will get rehandled.  If there are persistent errors, that should be treated
  # as a bug.
  def before_fulfilling
    Fulfillment.log "before_fulfilling start"
    if tracking.blank?
      Fulfillment.fulfill(self)     # throws :halt on error, which aborts transition
    else
      Fulfillment.log "skipping warehouse fulfillment - existing tracking code #{tracking}"
    end
    Fulfillment.log "before_fulfilling end"
  end
  
  # Know about our new state - do not erase it accidentally.
  alias_method :orig_determine_state, :determine_state
  def determine_state(order)
    return state if ['fulfilling', 'fulfill_fail'].include?(state)
    orig_determine_state(order)
  end
  
  
end
