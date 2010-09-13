require File.expand_path('../ar_test_helper', __FILE__)

ActiveRecord::Migration.create_table :articles do |t|
  t.string :name
  t.string :status
end

class Article < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true
  default_scope :conditions => "articles.status = 'published'"
end

module FriendlyId
  module Test
    module ActiveRecordAdapter
      class DefaultScopeTest < ::Test::Unit::TestCase

        def setup
          Article.delete_all
          Slug.delete_all
        end

        test "slug should load sluggable without default scope" do
          Article.create!(:name => "hello world", :status => "draft")
          assert_not_nil Slug.first.sluggable
        end
      end
    end
  end
end
