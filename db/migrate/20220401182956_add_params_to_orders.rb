class AddParamsToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :options, :json
  end
end
