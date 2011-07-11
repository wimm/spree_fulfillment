class AmazonFulfillment
  
  def initialize(f)
    @fulfillment = f
  end
  
  def fulfill
    raise "wrong state #{@fulfillment.state}" unless @fulfillment.processing?
    raise 'right state'
  end
  
end
