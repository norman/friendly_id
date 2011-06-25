require File.expand_path("../helper.rb", __FILE__)

setup { Class.new ActiveRecord::Base }

test "models don't use friendly_id by default" do |klass|
  assert !klass.uses_friendly_id?
end

test "model classes should have a friendly id config" do |klass|
  assert klass.has_friendly_id(:name).friendly_id_config
end

test "should raise error when bad config options are set" do |klass|
  assert_raise ArgumentError do
    klass.has_friendly_id :name, :garbage => :in
  end
end

[User, Book].map {|klass| klass.has_friendly_id :name}

setup {User}

test "should reserve 'new' and 'edit' by default" do |klass|
  ["new", "edit"].each do |word|
    transaction do
      assert_raise(ActiveRecord::RecordInvalid) {klass.create! :name => word}
    end
  end
end

test "instances should have a friendly id" do |klass|
  with_instance_of(klass) {|record| assert record.friendly_id}
end

require File.expand_path("../shared.rb", __FILE__)
