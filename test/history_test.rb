require File.expand_path("../helper.rb", __FILE__)
require "friendly_id/migration"

CreateFriendlyIdSlugs.up

migration do |m|
  m.add_column :users, :slug, :string
end

User.send :include, FriendlyId::History
User.has_friendly_id :name

setup {User}


test "should insert record in slugs table on create" do |klass|
  with_instance_of(klass) {|record| assert !record.friendly_id_slugs.empty?}
end

test "should not create new slug record if friendly_id is not changed" do |klass|
  with_instance_of(klass) do |record|
    record.active = true
    record.save!
    assert_equal 1, FriendlyIdSlug.count
  end
end

test "should create new slug record when friendly_id changes" do |klass|
  with_instance_of(klass) do |record|
    record.name = record.name + "b"
    record.save!
    assert_equal 2, FriendlyIdSlug.count
  end
end

test "should be findable by old slugs" do |klass|
  with_instance_of(klass) do |record|
    old_friendly_id = record.friendly_id
    record.name = record.name + "b"
    record.save!
    assert found = klass.find_by_friendly_id(old_friendly_id)
    assert !found.readonly?
  end
end

require File.expand_path("../shared.rb", __FILE__)