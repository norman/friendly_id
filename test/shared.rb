test "finds should respect conditions" do |klass|
  with_instance_of(klass) do |record|
    assert_raise(ActiveRecord::RecordNotFound) do
      klass.where("1 = 2").find record.friendly_id
    end
  end
end

test "should be findable by friendly id" do |klass|
  with_instance_of(klass) {|record| assert klass.find record.friendly_id}
end

test "should be findable by id as integer" do |klass|
  with_instance_of(klass) {|record| assert klass.find record.id.to_i}
end

test "should be findable by id as string" do |klass|
  with_instance_of(klass) {|record| assert klass.find record.id.to_s}
end

test "should be findable by numeric friendly_id" do |klass|
  with_instance_of(klass, :name => "206") {|record| assert klass.find record.friendly_id}
end

test "to_param should return the friendly_id" do |klass|
  with_instance_of(klass) {|record| assert_equal record.friendly_id, record.to_param}
end

test "should be findable by themselves" do |klass|
  with_instance_of(klass) {|record| assert_equal record, klass.find(record)}
end

test "updating record's other values should not change the friendly_id" do |klass|
  with_instance_of klass do |record|
    old = record.friendly_id
    record.update_attributes! :active => false
    assert klass.find old
  end
end

test "instances found by a single id should not be read-only" do |klass|
  with_instance_of(klass) {|record| assert !klass.find(record.friendly_id).readonly?}
end

test "failing finds with unfriendly_id should raise errors normally" do |klass|
  assert_raise(ActiveRecord::RecordNotFound) {klass.find 0}
end
