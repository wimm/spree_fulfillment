class AmazonFulfillment
  
  ActiveMerchant::Fulfillment::AmazonService.class_eval do
    
    # Used to get an error back if the order doesn't exist, so we can stop endlessly
    # querying.
    def fetch_tracking_raw(oid)
      commit :outbound, :tracking, build_tracking_request(oid, {})
    end
    
    # Monkeypatch of the original parse_tracking_response to include carrier, ship date, and arrival time.
    # Changed lines are marked.
    def parse_tracking_response(document)
      response = {}
      response[:tracking_numbers] = {}

      track_node = REXML::XPath.first(document, '//ns1:FulfillmentShipmentPackage/ns1:TrackingNumber')
      if track_node
        id_node = REXML::XPath.first(document, '//ns1:MerchantFulfillmentOrderId')
        response[:tracking_numbers][id_node.text] = track_node.text
        # Changes start here:
        carrier = REXML::XPath.first(document, '//ns1:FulfillmentShipmentPackage/ns1:CarrierCode')
        ship_time = REXML::XPath.first(document, '//ns1:FulfillmentShipment/ns1:ShippingDateTime')
        eta = REXML::XPath.first(document, '//ns1:FulfillmentShipment/ns1:EstimatedArrivalDateTime')
        response[:fulfillment_info] = {}
        response[:fulfillment_info][id_node.text] = {}
        response[:fulfillment_info][id_node.text][:tracking_number] = track_node.text
        response[:fulfillment_info][id_node.text][:carrier] = carrier.text if carrier
        response[:fulfillment_info][id_node.text][:ship_time] = ship_time.text if ship_time
        response[:fulfillment_info][id_node.text][:eta] = eta.text if eta
        # Changes end here
      end

      response[:response_status] = SUCCESS
      response
    end
    
    
  end
  

  def initialize(s)
    @shipment = s
  end
  
  # For Amazon these are the API access key and secret.
  def credentials
    { :login => Fulfillment.config[:api_key], :password => Fulfillment.config[:secret_key] }
  end
  
  def remote
    @remote ||= ActiveMerchant::Fulfillment::AmazonService.new(credentials)
  end
  
  def shipping_method
    case @shipment.shipping_method.name.downcase
    when /expedited/
      'Expedited'
    when /priority/
      'Priority'
    else
      'Standard'
    end
  end
  
  def options
    {
      :shipping_method => shipping_method,
      :order_date => @shipment.order.created_at,
      :comment => 'Thank you for your order.',
      :email => @shipment.order.email
    }
  end
  
  def address
    addr = @shipment.address
    {
      :name => "#{addr.firstname} #{addr.lastname}",
      :address1 => addr.address1,
      :address2 => addr.address2,
      :city => addr.city,
      :state => addr.state.abbr,
      :country => addr.state.country.iso,
      :zip => addr.zipcode
    }
  end
  
  def line_items
    skus = @shipment.inventory_units.map do |io|
      sku = io.variant.sku
      raise "missing sku for #{io.variant}" if !sku || sku.empty?
      sku
    end.uniq
    skus.map do |sku|
      num = @shipment.inventory_units.select{|io| io.variant.sku == sku}.size
      { :sku => sku, :quantity => num }
    end
  end
  
  def ensure_shippable
    # Safety double-check.  I think Spree should already enforce this.
    unless @shipment.ready?
      Fulfillment.log "wrong state: #{@shipment.state}"
      throw :halt
    end
  end
  
  # Runs inside a state_machine callback.  So throwing :halt is how we abort things.
  def fulfill
    Fulfillment.log "AmazonFulfillment.fulfill start"
    ensure_shippable
    num = @shipment.number
    addr = address
    li = line_items
    opts = options
    Fulfillment.log "#{num}; #{addr}; #{li}; #{opts}"

    begin
      resp = remote.fulfill(num, addr, li, opts)
      Fulfillment.log "#{resp.params}"
    rescue => e
      Fulfillment.log "failed - #{e}"
      throw :halt
    end
    
    # Stop the transition to shipped if there was an error.
    unless resp.success?
      if Fulfillment.config[:development_mode] && resp.params["faultstring"] =~ /ItemMissingCatalogData/
        # Ignore missing catalog items - can be handy for testing
        Fulfillment.log "ignoring missing catalog item (test / dev setting - should not see this on prod)"
      else
        Fulfillment.log "abort - response was in error"
        throw :halt
      end
    end
    Fulfillment.log "AmazonFulfillment.fulfill end"
  end
  
  # Returns the tracking number if there is one, else :error if there's a problem with the
  # shipment that will result in a permanent failure to fulfill, else nil.
  def track
    resp = remote.fetch_tracking_raw(@shipment.number)
    Fulfillment.log "#{resp.params}"
    # This can happen, for example, if the SKU doesn't exist.
    return :error if !resp.success? && resp.faultstring["requested order not found"]
    return nil unless resp.params["fulfillment_info"]      # not known yet
    resp.params["fulfillment_info"][@shipment.number]
  end
    
end
