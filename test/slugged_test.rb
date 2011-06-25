require File.expand_path("../helper.rb", __FILE__)

[User, Book].map do |klass|
  migration do |m|
    m.add_column klass.table_name, :slug, :string
    m.add_index  klass.table_name, :slug, :unique => true
  end
  klass.send :include, FriendlyId::Slugged
  klass.has_friendly_id :name
end

setup { User }

require File.expand_path("../shared.rb", __FILE__)

test "configuration should have a sequence_separator" do |klass|
  assert !klass.friendly_id_config.sequence_separator.empty?
end

test "should make a new slug if the friendly_id method value has changed" do |klass|
  with_instance_of klass do |record|
    record.name = "Changed Value"
    record.save!
    assert_equal "changed-value", record.slug
  end
end

test "should increment the slug sequence for duplicate friendly ids" do |klass|
  with_instance_of klass do |record|
    record2 = klass.create! :name => record.name
    assert record2.friendly_id.match(/2\z/)
  end
end

test "should not add slug sequence on update after other conflicting slugs were added" do |klass|
  with_instance_of klass do |record|
    old = record.friendly_id
    record2 = klass.create! :name => record.name
    record.save!
    record.reload
    assert_equal old, record.to_param
  end
end
