SpreeFulfillment is a spree extension to do fulfillment processing via Amazon when a
shipment becomes ready.

The extension adds an additional state to the Shipment state machine called 'fulfilling'
which acts as the transition between 'ready' and 'shipped'.  When a shipment becomes
'ready' it is eligible for fulfillment.  A rake task intended to be called from a cron
job checks for ready shipments and initiates the fulfillment via the Amazon API.  If
the fulfillment transaction succeeds, the shipment enteres the 'fulfilling' state.

The cron job also queries Amazon for tracking numbers of any orders that are being
fulfilled.  If the tracking numbers are found, the shipment transitions into
the 'shipped' state and an email is sent to the customer.


## Installation

### Add to your gemfile:

```ruby
gem 'whenever', :require => false      # if you want whenever to manage the cron job
gem 'spree_fulfillment', :git => 'git://github.com/wimm/spree_fulfillment.git'
```

### Create config/fulfillment.yml:

```yml
development:
  adapter: amazon
  api_key: <YOUR AMAZON AWS API KEY>
  secret_key: <YOUR AMAZON AWS SECRET KEY>
  development_mode: true

test:
  adapter: amazon
  api_key: <YOUR AMAZON AWS API KEY>
  secret_key: <YOUR AMAZON AWS SECRET KEY>

production:
  adapter: amazon
  api_key: <YOUR AMAZON AWS API KEY>
  secret_key: <YOUR AMAZON AWS SECRET KEY>
```

### Create config/schedule.rb:

```ruby
every :hour do
  rake "spree_fulfillment:process"
end
```

### Add to deploy.rb:

```ruby
require 'whenever/capistrano'      # if you want whenever to manage the cron job
```

### Add to your application initializer:

spree_fulfillment depends on active_fulfillment which conflicts with some newer source
files needed by spree_core.

```ruby
# A bit of hackery is needed to load the newer libraries inside ActiveMerchant before
# the obsolete ones still bundled inside the active_fulfillment gem.
ActiveMerchant::Connection.new("")
require 'active_fulfillment'
```

### Configure the store

Set the SKU code for your products to be equal to the Amazon fulfillment SKU code.


----

Copyright (c) 2011 WIMM Labs, released under the New BSD License
