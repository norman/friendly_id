module FriendlyId::NonSluggableClassMethods

  def self.extended(base)
    class << base
      alias_method_chain :find_one, :friendly
      alias_method_chain :find_some, :friendly
    end
  end

  # Finds the record using only the friendly id. If it can't be found
  # using the friendly id, then it returns false. If you pass in any
  # argument other than an instance of String or Array, then it also
  # returns false.
  # def find_using_friendly_id()
  #   return false unless slug_text.kind_of?(String)
  #   finder = "find_by_#{self.friendly_id_options[:column].to_s}".to_sym
  #   record = send(finder, slug_text)
  #   record.send(:found_using_friendly_id=, true) if record
  #   return record
  # end
  def find_one_with_friendly(id, options)
    if id.is_a?(String) && result = send("find_by_#{ friendly_id_options[:column] }", id, options)
      result.found_using_friendly_id = true
    else
      result = find_one_without_friendly id, options
    end
    result
  end

  def find_some_with_friendly(ids_and_names, options)
    results_by_name = with_scope :find => options do
      find :all, :conditions => ["#{ quoted_table_name }.#{ friendly_id_options[:column] } IN (?)", ids_and_names]
    end

    ids     = ids_and_names - results_by_name.map { |r| r[ friendly_id_options[:column] ] }
    results = results_by_name

    results += with_scope :find => options do
      find :all, :conditions => ["#{ quoted_table_name }.#{ primary_key } IN (?)", ids]
    end unless ids.empty?

    expected_size = options[:offset] ? ids_and_names.size - options[:offset] : ids_and_names.size
    expected_size = options[:limit] if options[:limit] && expected_size > options[:limit]

    raise ActiveRecord::RecordNotFound, "Couldn't find all #{ name.pluralize } with IDs (#{ ids_and_names * ', ' }) AND #{ sanitize_sql options[:conditions] } (found #{ results.size } results, but was looking for #{ expected_size })" if results.size != expected_size

    results_by_name.each { |r| r.found_using_friendly_id = true }
    results
  end
end
