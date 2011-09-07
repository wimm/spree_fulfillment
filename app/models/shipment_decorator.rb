Shipment.class_eval do
  
  scope :fulfilling, where(:state => 'fulfilling')
  
  state_machines[:state] = nil    # reset original state machine to start from scratch.

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
    before_transition :to => 'fulfilling', :do => :before_fulfilling  # new callback
    after_transition :to => 'shipped', :do => :after_ship
  end
  
  
  # If there's an error submitting to the fulfillment service, we should halt
  # the transition to 'fulfill' and stay in 'ready'.  That way transient errors
  # will get rehandled.  If there are persistent errors, that should be treated
  # as a bug.
  def before_fulfilling
    Fulfillment.log "before_fulfilling start"
    Fulfillment.fulfill(self)     # throws :halt on error, which aborts transition
    Fulfillment.log "before_fulfilling end"
  end
  
  # Know about our new state - do not erase it accidentally.
  alias_method :orig_determine_state, :determine_state
  def determine_state(order)
    return "fulfilling" if state == "fulfilling"
    orig_determine_state(order)
  end
  
  
end
