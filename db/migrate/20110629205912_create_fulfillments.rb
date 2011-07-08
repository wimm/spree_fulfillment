class CreateFulfillments < ActiveRecord::Migration
  def self.up
    create_table :fulfillments do |t|
      t.references :order, :null => false
      t.string :state
      t.string :reference
      t.timestamps
    end
    add_index :fulfillments, :order_id
  end

  def self.down
    drop_table :fulfillments
  end
end
