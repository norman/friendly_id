require "friendly_id/migration"
ActiveRecord::Migration.verbose = true

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

          add_column :novels, :novelist_id, :integer
        end

        private

        def slugged_tables
          ["journalists", "articles", "novelists", "novels"]
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
