class CreateCountries < ActiveRecord::Migration[5.2]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :iso_code_alpha_2
      t.string :iso_code_num
      t.string :country_calling_code
      t.string :currency
      t.string :language

      t.timestamps
    end
  end
end
