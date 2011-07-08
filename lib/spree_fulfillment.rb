require 'spree_core'
require 'spree_fulfillment_hooks'


module SpreeFulfillment
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      
      Order.class_eval do
        
        alias_method :orig_process_payments!, :process_payments!
        def process_payments!
          orig_process_payments!
          raise "fulfillment awaits you, lord!"
        end
        
      end
      
    end

    config.to_prepare &method(:activate).to_proc
  end
end


