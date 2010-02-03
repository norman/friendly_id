module FriendlyId
  module Sequel
    class CreateSlugs < ::Sequel::Migration

      def up
        create_table :slugs do
          primary_key :id, :type => Integer
          string :name
          integer :sluggable_id
          integer :sequence, :null => false, :default => 1
          string :sluggable_type, :limit => 40
          string :scope
          timestamp :created_at
        end
        add_index :slugs, :sluggable_id
        add_index :slugs, [:name, :sluggable_type, :sequence, :scope], :name => "index_slugs_on_n_s_s_and_s", :unique => true
      end

      def down
        drop_table :slugs
      end

    end
  end
end