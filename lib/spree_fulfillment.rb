require 'spree_core'
require 'spree_fulfillment_hooks'


module SpreeFulfillment
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      
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
      
      
      Shipment.class_eval do
        
        
        # Adding transition calls to the base spree_core state machine.
        # Not following the advice in the Spree extension guide to redeclare
        # everything, because that leads to multiple callbacks on the same edge.
        state_machine do

          # This transition does not work in the normal flow because there is logic
          # in the shipment class inside update! to avoid the callbacks.  So we override
          # update! as well.
          after_transition :to => 'ready', :do => :post_ready_fulfill

          before_transition :to => 'shipped', :do => :pre_ship_fulfill

        end
        
        
        def post_ready_fulfill
          Fulfillment.log "post_ready_fulfill"
          # Remember this shipment so we can call ship on it later when it's safe to do so.
          Spree::BaseController.fulfillment_store(self.id)
          true
        end
        
        def pre_ship_fulfill
          Fulfillment.log "pre_ship_fulfill start"
          Fulfillment.fulfill(self)
          Fulfillment.log "pre_ship_fulfill end"
          true
        end
        
        # The only purpose of this override is to work around spree's disabling of the
        # state_machine callbacks during order.update!
        alias_method :orig_update!, :update!
        def update!(order)
          old_state = self.state
          orig_update!(order)
          new_state = self.state
          post_ready_fulfill if new_state == 'ready' and old_state != 'ready'
        end
      
      end
      
    end

    config.to_prepare &method(:activate).to_proc
  end
end
