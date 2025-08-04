require "helper"

class JournalistWithFriendlyFinders < ActiveRecord::Base
  self.table_name = "journalists"
  extend FriendlyId
  scope :existing, -> { where("1 = 1") }
  friendly_id :name, use: [:slugged, :finders]
end

class Finders < TestCaseClass
  include FriendlyId::Test

  def model_class
    JournalistWithFriendlyFinders
  end

  test "should find records with finders as class methods" do
    with_instance_of(model_class) do |record|
      assert model_class.find(record.friendly_id)
    end
  end

  test "should find records with finders on relations" do
    with_instance_of(model_class) do |record|
      assert model_class.existing.find(record.friendly_id)
    end
  end

  test "allows nil with allow_nil: true" do
    with_instance_of(model_class) do |record|
      assert_nil model_class.find("foo", allow_nil: true)
    end
  end

  test "allows nil on relations with allow_nil: true" do
    with_instance_of(model_class) do |record|
      assert_nil model_class.existing.find("foo", allow_nil: true)
    end
  end

  test "allows nil with a bad primary key ID and allow_nil: true" do
    with_instance_of(model_class) do |record|
      assert_nil model_class.find(0, allow_nil: true)
    end
  end

  test "allows nil on relations with a bad primary key ID and allow_nil: true" do
    with_instance_of(model_class) do |record|
      assert_nil model_class.existing.find(0, allow_nil: true)
    end
  end

  test "allows nil with a bad potential primary key ID and allow_nil: true" do
    with_instance_of(model_class) do |record|
      assert_nil model_class.find("0", allow_nil: true)
    end
  end

  test "allows nil on relations with a bad potential primary key ID and allow_nil: true" do
    with_instance_of(model_class) do |record|
      assert_nil model_class.existing.find("0", allow_nil: true)
    end
  end

  test "allows nil with nil ID and allow_nil: true" do
    with_instance_of(model_class) do |record|
      assert_nil model_class.find(nil, allow_nil: true)
    end
  end

  test "allows nil on relations with nil ID and allow_nil: true" do
    with_instance_of(model_class) do |record|
      assert_nil model_class.existing.find(nil, allow_nil: true)
    end
  end

  # Array finder tests
  test "should find records by array of slugs" do
    with_instances_of(model_class, 2) do |record1, record2|
      slugs = [record1.friendly_id, record2.friendly_id]
      found_records = model_class.find(slugs)
      
      assert_equal 2, found_records.size
      assert_includes found_records, record1
      assert_includes found_records, record2
    end
  end

  test "should find records by array of numeric IDs" do
    with_instances_of(model_class, 2) do |record1, record2|
      ids = [record1.id, record2.id]
      found_records = model_class.find(ids)
      
      assert_equal 2, found_records.size
      assert_includes found_records, record1
      assert_includes found_records, record2
    end
  end

  test "should find records by mixed array of slugs and numeric IDs" do
    with_instances_of(model_class, 2) do |record1, record2|
      mixed_ids = [record1.friendly_id, record2.id]
      found_records = model_class.find(mixed_ids)
      
      assert_equal 2, found_records.size
      assert_includes found_records, record1
      assert_includes found_records, record2
    end
  end

  test "should return empty array for empty array input" do
    result = model_class.find([])
    assert_equal [], result
  end

  test "should raise RecordNotFound for non-existent slug in array" do
    with_instance_of(model_class) do |record|
      slugs = [record.friendly_id, "non-existent-slug"]
      
      assert_raises(ActiveRecord::RecordNotFound) do
        model_class.find(slugs)
      end
    end
  end

  test "should raise RecordNotFound for non-existent ID in array" do
    with_instance_of(model_class) do |record|
      ids = [record.id, 99999]
      
      assert_raises(ActiveRecord::RecordNotFound) do
        model_class.find(ids)
      end
    end
  end

  test "should raise RecordNotFound for mixed array with non-existent items" do
    with_instance_of(model_class) do |record|
      mixed_ids = [record.friendly_id, 99999]
      
      assert_raises(ActiveRecord::RecordNotFound) do
        model_class.find(mixed_ids)
      end
    end
  end

  test "should return partial results with allow_nil for array with non-existent slugs" do
    with_instance_of(model_class) do |record|
      slugs = [record.friendly_id, "non-existent-slug"]
      found_records = model_class.find(slugs, allow_nil: true)
      
      assert_equal 1, found_records.size
      assert_includes found_records, record
    end
  end

  test "should return partial results with allow_nil for array with non-existent IDs" do
    with_instance_of(model_class) do |record|
      ids = [record.id, 99999]
      found_records = model_class.find(ids, allow_nil: true)
      
      assert_equal 1, found_records.size
      assert_includes found_records, record
    end
  end

  test "should work with array finders on relations" do
    with_instances_of(model_class, 2) do |record1, record2|
      slugs = [record1.friendly_id, record2.friendly_id]
      found_records = model_class.existing.find(slugs)
      
      assert_equal 2, found_records.size
      assert_includes found_records, record1
      assert_includes found_records, record2
    end
  end

  test "should handle array with single slug" do
    with_instance_of(model_class) do |record|
      found_records = model_class.find([record.friendly_id])
      
      assert_equal 1, found_records.size
      assert_equal record, found_records.first
    end
  end

  test "should handle array with single numeric ID" do
    with_instance_of(model_class) do |record|
      found_records = model_class.find([record.id])
      
      assert_equal 1, found_records.size
      assert_equal record, found_records.first
    end
  end

  # Helper method to create multiple instances
  def with_instances_of(model_class, count)
    instances = count.times.map do |i|
      model_class.create(name: "Test Record #{i + 1}")
    end
    
    yield(*instances)
  ensure
    instances&.each(&:destroy)
  end
end
