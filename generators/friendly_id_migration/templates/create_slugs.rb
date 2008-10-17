class CreateSlugs < ActiveRecord::Migration
  def self.up
    create_table :slugs do |t|
      t.string :name
      t.string :sluggable_type
      t.integer :sluggable_id
      t.timestamps
    end
    add_index :slugs, [:name, :sluggable_type], :unique => true
    add_index :slugs, :sluggable_id
  end

  def self.down
    drop_table :slugs
  end
end
