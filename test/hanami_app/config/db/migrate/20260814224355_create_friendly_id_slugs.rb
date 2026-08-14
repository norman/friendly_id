# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :friendly_id_slugs do
      primary_key :id
      column :slug, String, null: false
      column :sluggable_id, Integer, null: false
      column :sluggable_type, String, size: 50
      column :scope, String
      column :created_at, Time

      index [:sluggable_type, :sluggable_id]
      index [:slug, :sluggable_type]
      index [:slug, :sluggable_type, :scope], unique: true
    end
  end
end
