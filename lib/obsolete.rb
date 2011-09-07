# This code is obsolete and should not be used.  It's here only for
# archeological purposes.

raise "obsolete code should not be loaded"      # enforce no-op file


# Cleanup: should move these class modifications to decorator files.
# http://groups.google.com/group/spree-user/browse_thread/thread/5e43999179e65dfa/b3d5bab17de0026e

# This provides a place to remember objects that need processing outside of
# the restrictions on spree's order.update! method.  That is, to avoid infinite
# recursion.

# Should find a cleaner way to do a per request cache, maybe something like
# http://stackoverflow.com/questions/660599/rails-per-request-hash

Spree::BaseController.class_eval do
  
  before_filter :fulfill_before_filter
  after_filter :fulfill_after_filter
  
  def fulfill_before_filter
    @@fulfillment_store = [] unless defined?(@@fulfillment_store)
  end

  def fulfill_after_filter
    #Rails.logger.info '*' * 10 + "fulfill_after_filter #{@@fulfillment_store}"
    @@fulfillment_store.each do |sid|
      # Ship everything that's hinted to be ready to ship.
      s = Shipment.find(sid)
      next unless s && s.ready?
      Fulfillment.log "sending shipment #{sid}"
      s.ship!
    end
    @@fulfillment_store = []
  end
  
  def self.fulfillment_store(x)
    return unless defined?(@@fulfillment_store)   # can happen from rails console
    @@fulfillment_store << x
  end
  
end



# Pass the order email through to Amazon.  One line added.
# See https://forums.aws.amazon.com/thread.jspa?messageID=173074&#173074
# This never seemed to do anything.
ActiveMerchant::Fulfillment::AmazonService.class_eval do

  def build_fulfillment_request(order_id, shipping_address, line_items, options)
    request = OPERATIONS[:outbound][:create]
    soap_request(request) do |xml|
      xml.tag! request, { 'xmlns' => SERVICES[:outbound][:xmlns] } do
        xml.tag! "MerchantFulfillmentOrderId", order_id
        xml.tag! "DisplayableOrderId", order_id
        xml.tag! "DisplayableOrderDateTime", options[:order_date].strftime("%Y-%m-%dT%H:%M:%SZ")
        xml.tag! "DisplayableOrderComment", options[:comment]
        xml.tag! "ShippingSpeedCategory", options[:shipping_method]
        xml.tag! "ShippingSpeedCategory", options[:shipping_method]
        
        # Adding this line...
        xml.tag! "NotificationEmailList.1", options[:email]

        add_address(xml, shipping_address)
        add_items(xml, line_items)
      end
    end
  end

end
