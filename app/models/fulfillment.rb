class Fulfillment
  
  CONFIG_FILE = "#{Rails.root}/config/fulfillment.yml"
  CONFIG = HashWithIndifferentAccess.new(YAML.load_file(CONFIG_FILE)[Rails.env])
  
  
  def self.fulfill(shipment)
    ca = CONFIG[:adapter]
    raise "missing adapter config for #{Rails.env} -- check fulfillment.yml" unless ca
    (ca + '_fulfillment').camelize.constantize.new(shipment).fulfill
  end

  def self.config
    CONFIG
  end

  def self.log(msg)
    Rails.logger.info '**** spree_fulfillment: ' + msg
  end
  
  # Passes any shipments that are ready to the fulfillment service
  def self.process_ready
    log "process_ready start"
    Shipment.ready.each do |s|
      s.ship
    end
    log "process_ready finish"
  end
  
  # Gets tracking number and sends ship email when fulfillment house is done
  def self.process_shipped
    log "process_shipped start"
    log "process_shipped finish"
  end
  
end
