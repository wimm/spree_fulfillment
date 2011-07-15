class AmazonFulfillment
  
  def initialize(s)
    @shipment = s
  end
  
  def credentials
    { :login => Fulfillment.config[:api_key], :password => Fulfillment.config[:secret_key] }
  end
  
  def remote
    @remote ||= ActiveMerchant::Fulfillment::AmazonService.new(credentials)
  end
  
  def options
    {
      :shipping_method => 'Standard',
      :order_date => @shipment.order.created_at,
      :comment => 'Thank you for your order.'
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
  
  def fulfill
    raise "wrong state: #{@shipment.state}" unless @shipment.ready?
    num = @shipment.number
    addr = address
    li = line_items
    opts = options
    Fulfillment.log "#{num}; #{addr}; #{li}; #{opts}"
    resp = remote.fulfill(num, addr, li, opts)
    Fulfillment.log "#{resp.params}"
    resp.success?
  end
    
end
