class CreateSupportModels < ActiveRecord::Migration
  def self.up

    create_table :authors do |t|
      t.string :name
    end

    create_table :books do |t|
      t.string :name
      t.string :type
      t.string :note
    end

    create_table :cities do |t|
      t.string :name
      t.string :my_slug
      t.integer :population
    end

    create_table :countries do |t|
      t.string :name
    end

    create_table :districts do |t|
      t.string :name
      t.string :note
      t.string :cached_slug
    end

    create_table :events do |t|
      t.string :name
      t.datetime :event_date
    end

    create_table :houses do |t|
      t.string :name
      t.integer :user_id
    end

    create_table :legacy_table do |t|
      t.string :name
      t.string :note
    end

    create_table :people do |t|
      t.string :name
    end

    create_table :posts do |t|
      t.string :name
      t.boolean :published
      t.string :note
    end

    create_table :residents do |t|
      t.string :name
      t.integer :country_id
    end

    create_table :users do |t|
      t.string :name
      t.index :name, :unique => true
    end

  end

  def self.down
  end
end

