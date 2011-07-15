class Fulfillment
  
  CONFIG_FILE = "#{Rails.root}/config/fulfillment.yml"
  CONFIG = HashWithIndifferentAccess.new(YAML.load_file(CONFIG_FILE)[Rails.env])
  
  
  def self.fulfill(shipment)
    (config[:adapter] + '_fulfillment').camelize.constantize.new(shipment).fulfill
  end

  def self.config
    CONFIG
  end

  def self.log(msg)
    Rails.logger.info '**** spree_fulfillment: ' + msg
  end
  
end
