require "helper"

class JournalistWithFriendlyFinders < ActiveRecord::Base
  self.table_name = 'journalists'
  extend FriendlyId
  scope :existing, -> {where('1 = 1')}
  friendly_id :name, use: [:slugged, :finders]
end

class Finders < TestCaseClass

  include FriendlyId::Test

  def model_class
    JournalistWithFriendlyFinders
  end

  test 'should find records with finders as class methods' do
    with_instance_of(model_class) do |record|
      assert model_class.find(record.friendly_id)
    end
  end

  test 'should find records with finders on relations' do
    with_instance_of(model_class) do |record|
      assert model_class.existing.find(record.friendly_id)
    end
  end

  test 'should raise an error with full information' do
    with_instance_of(model_class) do |record|
      assert_raises(ActiveRecord::RecordNotFound) do |e|
        model_class.find("invalid-id-1")
      end
      begin
        model_class.find("invalid-id-1")
      rescue ActiveRecord::RecordNotFound => e
        assert_equal %Q(can't find record with friendly id: "invalid-id-1"), e.message
        if ActiveRecord::VERSION::MAJOR == 5
          assert_equal "JournalistWithFriendlyFinders", e.model
        end
      end
    end
  end
end
