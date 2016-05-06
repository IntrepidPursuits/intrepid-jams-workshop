class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.references :game, index: true, foreign_key: true
      t.string :name
      t.integer :score
      t.string :player_names

      t.timestamps null: false
    end
  end
end
