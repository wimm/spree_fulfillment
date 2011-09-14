class Fulfillment
  
  CONFIG_FILE = "#{Rails.root}/config/fulfillment.yml"
  CONFIG = HashWithIndifferentAccess.new(YAML.load_file(CONFIG_FILE)[Rails.env])
  
  
  def self.service_for(shipment)
    ca = CONFIG[:adapter]
    raise "missing adapter config for #{Rails.env} -- check fulfillment.yml" unless ca
    (ca + '_fulfillment').camelize.constantize.new(shipment)
  end
  
  def self.fulfill(shipment)
    service_for(shipment).fulfill
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
    Shipment.ready.map(&:id).each do |sid|
      Shipment.transaction do
        begin
          # Use locking to avoid multiple shipments due to race conditions.
          # Note there's some risk of deadlock and bad behavior due to holding
          # a lock over a third party remote transaction which might be slow.
          s = Shipment.find(sid, :lock => true)
          if s && s.state == "ready"
            s.ship
          else
            log "skipping ship for id #{sid} : #{s} #{s.try(:state)}"
          end
        rescue => e
          log "failed to ship id #{sid} due to #{e}"
          Airbrake.notify(e) if defined?(Airbrake)
          # continue on and try other shipments so that one bad shipment doesn't
          # block an entire queue
        end
      end
    end
    log "process_ready finish"
  end
  
  # Gets tracking number and sends ship email when fulfillment house is done
  def self.process_shipped
    log "process_shipped start"
    Shipment.fulfilling.each do |s|
      begin
        log "querying tracking status for #{s.id}"
        tracking = service_for(s).track
        next unless tracking      # nil means we don't know yet.
        if tracking == :error
          log "failed at warehouse"
          s.fail_at_warehouse     # put into a permanent error state for inspection / repair
        else
          log "got tracking number: #{tracking}"
          s.update_attribute(:tracking, tracking)
          s.ship_from_warehouse   # new tracking code means we just shipped
        end
      rescue => e
        log "failed to get tracking info for id #{s.id} due to #{e}"
        Airbrake.notify(e) if defined?(Airbrake)
        # continue on and try other shipments so that one bad shipment doesn't
        # block an entire queue
      end
    end
    log "process_shipped finish"
  end
  
end
