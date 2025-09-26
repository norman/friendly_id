require "helper"

class Article < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
end

class NumericSlugTest < TestCaseClass
  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Article
  end

  test "should generate numeric slugs by default" do
    transaction do
      record = model_class.create! name: "123"
      assert_equal "123", record.slug
    end
  end

  test "should find by numeric slug by default" do
    transaction do
      record = model_class.create! name: "123"
      assert_equal model_class.friendly.find("123").id, record.id
    end
  end

  test "should exist? by numeric slug by default" do
    transaction do
      model_class.create! name: "123"
      assert model_class.friendly.exists?("123")
    end
  end
end

class NumericSlugConflictTest < TestCaseClass
  include FriendlyId::Test

  class ArticleWithNumericPrevention < ActiveRecord::Base
    self.table_name = "articles"
    extend FriendlyId
    friendly_id :name, use: :slugged
    friendly_id_config.treat_numeric_as_conflict = true
  end

  def model_class
    ArticleWithNumericPrevention
  end

  test "should prevent purely numeric slugs when treat_numeric_as_conflict is enabled" do
    transaction do
      record = model_class.create! name: "123"
      refute_equal "123", record.slug
      assert_match(/\A123-[0-9a-f-]{36}\z/, record.slug)
    end
  end

  test "should allow non-numeric slugs when treat_numeric_as_conflict is enabled" do
    transaction do
      record = model_class.create! name: "abc123"
      assert_equal "abc123", record.slug
    end
  end

  test "should allow alphanumeric slugs when treat_numeric_as_conflict is enabled" do
    transaction do
      record = model_class.create! name: "product-123"
      assert_equal "product-123", record.slug
    end
  end

  test "should handle zero as numeric" do
    transaction do
      record = model_class.create! name: "0"
      refute_equal "0", record.slug
      assert_match(/\A0-[0-9a-f-]{36}\z/, record.slug)
    end
  end

  test "should handle large numbers as numeric" do
    transaction do
      record = model_class.create! name: "999999999"
      refute_equal "999999999", record.slug
      assert_match(/\A999999999-[0-9a-f-]{36}\z/, record.slug)
    end
  end

  test "should find records with UUID-suffixed numeric slugs" do
    transaction do
      record = model_class.create! name: "123"
      found = model_class.friendly.find(record.slug)
      assert_equal record.id, found.id
    end
  end

  test "should resolve conflicts between multiple numeric slugs" do
    transaction do
      record1 = model_class.create! name: "456"
      record2 = model_class.create! name: "456"

      refute_equal record1.slug, record2.slug
      assert_match(/\A456-[0-9a-f-]{36}\z/, record1.slug)
      assert_match(/\A456-[0-9a-f-]{36}\z/, record2.slug)
    end
  end
end
