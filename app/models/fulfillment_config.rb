class FulfillmentConfig
  
  CONFIG = YAML.load_file("#{Rails.root}/config/fulfillment.yml")[Rails.env]
  
  def self.[](k)
    CONFIG[k.to_s]
  end
  
end
