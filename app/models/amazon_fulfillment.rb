class AmazonFulfillment
  
  def initialize(f)
    @fulfillment = f
  end
  
  def process
    raise "wrong state #{f.state}" unless f.processing?
    
  end
  
end
