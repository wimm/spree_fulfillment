namespace :spree_fulfillment do
  
  desc "Handles shipments that are ready for or have completed fulfillment"
  task :process => :environment do
    Rake::Task['spree_fulfillment:process:ready'].invoke
    Rake::Task['spree_fulfillment:process:shipped'].invoke
  end
  
  namespace :process do
  
    desc "Passes any shipments that are ready to the fulfillment service"
    task :ready do
      Fulfillment.process_ready
    end

    desc "Gets tracking number and sends ship email when fulfillment house is done"
    task :shipped do
      Fulfillment.process_shipped
    end
  
  end

end
