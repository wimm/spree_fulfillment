SpreeFulfillment
================

Spree extension to do fulfillment processing via Amazon when a shipment becomes ready.

The extension adds an additional state to the Shipment state machine called 'fulfill'
which acts as the transition between 'ready' and 'shipped'.  When a shipment becomes
'ready' it is eligible for fulfillment.  A rake task intended to be called from a cron
job checks for ready shipments and initiates the fulfillment via the Amazon API.  If
the fulfillment transaction succeeds, the shipment enteres the 'fulfill' state.

The cron job also queries Amazon for tracking numbers of any orders that are being
fulfilled.  If the tracking numbers are found, the shipment transitions into
the 'shipped' state and an email is sent to the customer.



Copyright (c) 2011 WIMM Labs, released under the New BSD License
