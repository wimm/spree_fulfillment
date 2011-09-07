# Fix a bug with rounding to the penny for sales tax.
# See http://groups.google.com/group/spree-user/browse_thread/thread/374410d4dea30b6c
Calculator::SalesTax.class_eval do

  alias_method :orig_compute, :compute
  def compute(order)
    value = orig_compute(order)
    rounded = (value * 100).round.to_f / 100
    Fulfillment.log "rounded #{value} to #{rounded}"
    rounded
  end
  
end
