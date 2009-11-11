# encoding: utf-8

module FriendlyId::NonSluggableClassMethods

  include FriendlyId::Helpers

  protected

  def find_one(id, options) #:nodoc:#
    if id.is_a?(String) && result = send("find_by_#{ friendly_id_options[:method] }", id, options)
      result.send(:found_using_friendly_id=, true)
    else
      result = super id, options
    end
    result
  end

  def find_some(ids_and_names, options) #:nodoc:#

    results = with_scope :find => options do
      find :all, :conditions => ["#{quoted_table_name}.#{primary_key} IN (?) OR #{friendly_id_options[:method].to_s} IN (?)",
        ids_and_names, ids_and_names]
    end

    expected = expected_size(ids_and_names, options)
    if results.size != expected
      raise ActiveRecord::RecordNotFound, "Couldn't find all #{ name.pluralize } with IDs (#{ ids_and_names * ', ' }) AND #{ sanitize_sql options[:conditions] } (found #{ results.size } results, but was looking for #{ expected })"
    end

    results.each {|r| r.send(:found_using_friendly_id=, true) if ids_and_names.include?(r.friendly_id)}

    results

  end
end
