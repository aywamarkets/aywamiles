class CreatePartnerOrganizations < ActiveRecord::Migration[5.2]
  def change
    create_table :partner_organizations do |t|
      t.string :name
      t.string :description
      t.string :payment_network
      t.string :status
      t.integer :country_id

      t.timestamps
    end

    add_index :partner_organizations, :payment_network,       unique: true
    add_index :partner_organizations, :status
    add_index :partner_organizations, :country_id
  end
end
