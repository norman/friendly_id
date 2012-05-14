class CreateFriendlyIdSlugs < ActiveRecord::Migration
  def change
    create_table :friendly_id_slugs do |t|
      t.string   :slug,           :null => false
      t.references :sluggable, :polymorphic => true, :null => false
      t.datetime :created_at

      t.index :sluggable_id
      t.index [:slug, :sluggable_type], :unique => true
      t.index :sluggable_type
    end
  end
end
