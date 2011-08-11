require "friendly_id/migration"

module FriendlyId
  module Test
    class Schema < ActiveRecord::Migration
      class << self
        def down
          CreateFriendlyIdSlugs.down
          tables.each do |name|
            drop_table name
          end
        end

        def up
          CreateFriendlyIdSlugs.up

          tables.each do |table_name|
            create_table table_name do |t|
              t.string  :name
              t.boolean :active
            end
          end

          slugged_tables.each do |table_name|
            add_column table_name, :slug, :string
            add_index  table_name, :slug, :unique => true
          end

          # This will be used to test scopes
          add_column :novels, :novelist_id, :integer
          remove_index :novels, :slug

          # This will be used to test column name quoting
          add_column :journalists, "strange name", :string

          # This will be used to test STI
          add_column :journalists, "type", :string
        end

        private

        def slugged_tables
          ["journalists", "articles", "novelists", "novels", "manuals"]
        end

        def simple_tables
          ["authors", "books"]
        end

        def tables
          simple_tables + slugged_tables
        end
      end
    end
  end
end