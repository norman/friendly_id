class CreateFriendlyIdSlugs < ActiveRecord::Migration
  def change
    create_table :friendly_id_slugs do |t|
      t.string   :slug,           :null => false
      t.integer  :sluggable_id,   :null => false
      t.string   :sluggable_type, :limit => 50
      t.string   :scope
      t.datetime :created_at
    end
    add_index :friendly_id_slugs, :sluggable_id
    add_index :friendly_id_slugs, [:slug, :sluggable_type], length: { name: 100, slug: 20, sluggable_type: 20 }
    add_index :friendly_id_slugs, [:slug, :sluggable_type, :scope], length: { name: 100, slug: 20, sluggable_type: 20, scope: 20 }, unique: true
    add_index :friendly_id_slugs, :sluggable_type
  end
end
