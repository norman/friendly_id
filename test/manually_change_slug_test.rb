require 'helper'

class Article < ActiveRecord::Base
  extend FriendlyId

  friendly_id :name, use: [:sequentially_slugged, :history]

  protected

  def should_generate_new_friendly_id?
    slug.blank?
  end

  def should_manually_change_friendly_id?
    slug_changed?
  end
end

class ManuallyChangeSlugTest < TestCaseClass
  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Article
  end

  test "should generate slug when it is blank" do
    transaction do
      record1 = model_class.create(name: 'Some cool article')

      assert_equal 'some-cool-article', record1.slug
    end
  end

  test "should not generate slug when it is already exists" do
    transaction do
      record1 = model_class.create(name: 'Some cool article')

      assert_equal 'some-cool-article', record1.slug

      record1.update_attributes(name: 'Another news')

      assert_equal 'some-cool-article', record1.slug
    end
  end

  test "should be able to change slug manually considering history" do
    transaction do
      record1 = model_class.create(name: 'About us')
      assert_equal 'about-us', record1.slug

      record1.update_attributes(slug: 'something-about-us')
      assert_equal 'something-about-us', record1.slug
      assert_equal record1.slugs.count, 2

      record2 = model_class.create(name: 'Yes, you win!')
      assert_equal 'yes-you-win', record2.slug

      record2.update_attributes(slug: 'about-us')
      assert_equal 'about-us-2', record2.slug

      record2.update_attributes(slug: 'something about us')
      assert_equal 'something-about-us-2', record2.slug
      assert_equal record2.slugs.count, 3
    end
  end
end
