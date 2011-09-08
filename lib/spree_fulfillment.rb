require 'spree_core'


module SpreeFulfillment
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        # For gem extensions, it appears that require is usable in dev and prod modes
        # to load the patches once and only once.
        require(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
