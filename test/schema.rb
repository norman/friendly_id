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
          # TODO: use schema version to avoid ugly hacks like this
          return if @done
          CreateFriendlyIdSlugs.migrate :up

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

          scoped_tables.each do |table_name|
            add_column table_name, :slug, :string
          end

          # This will be used to test scopes
          add_column :novels, :novelist_id, :integer
          add_column :novels, :publisher_id, :integer
          remove_index :novels, :slug
          add_index :novels, [:slug, :publisher_id, :novelist_id], :unique => true

          # This will be used to test column name quoting
          add_column :journalists, "strange name", :string

          # This will be used to test STI
          add_column :journalists, "type", :string

          # These will be used to test i18n
          add_column :journalists, "slug_en", :string
          add_column :journalists, "slug_es", :string
          add_column :journalists, "slug_de", :string

          # This will be used to test relationships
          add_column :books, :author_id, :integer

          # Used to test :scoped and :history together
          add_column :restaurants, :city_id, :integer

          @done = true
        end

        private

        def slugged_tables
          %w[journalists articles novelists novels manuals]
        end

        def scoped_tables
          ["restaurants"]
        end

        def simple_tables
          %w[authors books publishers cities]
        end

        def tables
          simple_tables + slugged_tables + scoped_tables
        end
      end
    end
  end
end
