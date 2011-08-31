module FriendlyId
  module Test
    module Shared

      module Slugged
        test "configuration should have a sequence_separator" do
          assert !model_class.friendly_id_config.sequence_separator.empty?
        end

        test "should make a new slug if the friendly_id method value has changed" do
          with_instance_of model_class do |record|
            record.name = "Changed Value"
            record.save!
            assert_equal "changed-value", record.slug
          end
        end

        test "should increment the slug sequence for duplicate friendly ids" do
          with_instance_of model_class do |record|
            record2 = model_class.create! :name => record.name
            assert record2.friendly_id.match(/2\z/)
          end
        end

        test "should not add slug sequence on update after other conflicting slugs were added" do
          with_instance_of model_class do |record|
            old = record.friendly_id
            model_class.create! :name => record.name
            record.save!
            record.reload
            assert_equal old, record.to_param
          end
        end

        test "should not increment sequence on save" do
          with_instance_of model_class do |record|
            record2 = model_class.create! :name => record.name
            record2.active = !record2.active
            record2.save!
            assert record2.friendly_id.match(/2\z/)
          end
        end

        test "should create slug on save if the slug is nil" do
          with_instance_of model_class do |record|
            record.slug = nil
            record.save!
            assert_nil record.slug
            record.save
            refute_nil record.slug
          end
        end

      end

      module Core
        test "finds should respect conditions" do
          with_instance_of(model_class) do |record|
            assert_raises(ActiveRecord::RecordNotFound) do
              model_class.where("1 = 2").find record.friendly_id
            end
          end
        end

        test "should be findable by friendly id" do
          with_instance_of(model_class) {|record| assert model_class.find record.friendly_id}
        end

        test "should be findable by id as integer" do
          with_instance_of(model_class) {|record| assert model_class.find record.id.to_i}
        end

        test "should be findable by id as string" do
          with_instance_of(model_class) {|record| assert model_class.find record.id.to_s}
        end

        test "should be findable by numeric friendly_id" do
          with_instance_of(model_class, :name => "206") {|record| assert model_class.find record.friendly_id}
        end

        test "to_param should return the friendly_id" do
          with_instance_of(model_class) {|record| assert_equal record.friendly_id, record.to_param}
        end

        test "should be findable by themselves" do
          with_instance_of(model_class) {|record| assert_equal record, model_class.find(record)}
        end

        test "updating record's other values should not change the friendly_id" do
          with_instance_of model_class do |record|
            old = record.friendly_id
            record.update_attributes! :active => false
            assert model_class.find old
          end
        end

        test "instances found by a single id should not be read-only" do
          with_instance_of(model_class) {|record| assert !model_class.find(record.friendly_id).readonly?}
        end

        test "failing finds with unfriendly_id should raise errors normally" do
          assert_raises(ActiveRecord::RecordNotFound) {model_class.find 0}
        end

        test "should return numeric id if the friendly_id is nil" do
          with_instance_of(model_class) do |record|
            record.expects(:friendly_id).returns(nil)
            assert_equal record.id.to_s, record.to_param
          end
        end

        test "should return numeric id if the friendly_id is an empty string" do
          with_instance_of(model_class) do |record|
            record.expects(:friendly_id).returns("")
            assert_equal record.id.to_s, record.to_param
          end
        end

        test "should return numeric id if the friendly_id is blank" do
          with_instance_of(model_class) do |record|
            record.expects(:friendly_id).returns("  ")
            assert_equal record.id.to_s, record.to_param
          end
        end
      end
    end
  end
end

