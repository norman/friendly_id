class UpgradeFriendlyIdTo20 < ActiveRecord::Migration

  def self.up
    remove_column :slugs, :updated_at
    remove_index :slugs, :column => [:name, :sluggable_type]
    add_column :slugs, :sequence, :integer, :null => false, :default => 1
    add_column :slugs, :scope, :string, :limit => 40
    add_index :slugs, [:name, :sluggable_type, :scope, :sequence], :unique => true, :name => "index_slugs_on_n_s_s_and_s"
  end

  def self.down
    remove_index :slugs, :name => "index_slugs_on_n_s_s_and_s"
    remove_column :slugs, :scope
    remove_column :slugs, :sequence
    add_column :slugs, :updated_at, :datetime
    add_index :slugs, [:name, :sluggable_type], :unique => true
  end

end