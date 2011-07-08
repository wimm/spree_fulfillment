class Fulfillment < ActiveRecord::Base
  
  belongs_to :order

  # There can be multiple failed fulfillments, but there should only be
  # one in any other state.  This is a check on multiple ship errors.
  validates_uniqueness_of :order_id, :scope => :state, :if => :may_complete?
  
  # fulfillment state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
  state_machine :initial => :ready do
    event :start do
      transition :ready => :processing
    end
    # When processing during checkout fails
    event :fail do
      transition :from => :processing, :to => :failed
    end
    # When processing during checkout succeeds
    event :complete do
      transition :from => :processing, :to => :completed
    end
    
    after_transition any => :processing {|f| f.do_processing}
  end
  
  
  # Here is where we actually initiate the fulfillment using the 3rd party service.
  def do_processing
    AmazonFulfillment.fulfill(self)
  end
  
  # True if this fulfillment has a chance of being shipped, or already shipped.
  def may_complete?
    state != 'failed'
  end
  
  # This is the key hook into the checkout process from the Spree framework.
  #
  # Given the order, we can get the ship address: order.ship_address
  # and a bunch of line items:  order.line_items
  # each of which links back to a product:  order.line_items.first.variant.product
  #
  def self.create_for(order)
    Fulfillment.transaction do
      # Another safety check on having multiple fulfillments on the same order.  Check
      # that everything else is in error state.
      prevs = Fulfillment.find_all_by_order_id(order.id)
      raise "can't re-fulfill" if prevs.detect{|f| f.may_complete?}
      
      Rails.logger.info "creating Fulfillment for order #{order.id}"
      f = Fulfillment.new(:order => order)
      f.save!
    end
    start!
  end

end
