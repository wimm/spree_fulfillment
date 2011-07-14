class AmazonFulfillment
  
  def initialize(f)
    @fulfillment = f
  end
  
  def credentials
    { :login => FulfillmentConfig[:api_key], :password => FulfillmentConfig[:secret_key] }
  end
  
  def remote
    @remote ||= ActiveMerchant::Fulfillment::AmazonService.new(credentials)
  end
  
  def fulfill
    raise "wrong state #{@fulfillment.state}" unless @fulfillment.processing?
    remote.status
  end
    
end
