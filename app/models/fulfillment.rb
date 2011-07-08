class Fulfillment < ActiveRecord::Base
  
  belongs_to :order

  scope :with_state, lambda {|s| where(:state => s)}
  scope :completed, with_state('completed')
  scope :pending, with_state('pending')
  scope :failed, with_state('failed')
  

  # fulfillment state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
  state_machine :initial => 'checkout' do
    event :started_processing do
      transition :from => ['checkout', 'pending', 'completed'], :to => 'processing'
    end
    # When processing during checkout fails
    event :fail do
      transition :from => 'processing', :to => 'failed'
    end
    # With card payments this represents authorizing the payment
    event :pend do
      transition :from => 'processing', :to => 'pending'
    end
    # With card payments this represents completing a purchase or capture transaction
    event :complete do
      transition :from => ['processing', 'pending'], :to => 'completed'
    end
  end


  def process!
    if !processing? and source and source.respond_to?(:process!)
      started_processing!
      source.process!(self) # source is responsible for updating the payment state when it's done processing
    end
  end

end

