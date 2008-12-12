module SluggableClassMethods

  def self.extended(base)

    class << base
      alias_method_chain :find_one, :friendly
      alias_method_chain :find_some, :friendly
      alias_method_chain :validate_find_options, :friendly
    end

    base.named_scope :with_slug_name, lambda {|slug_names| {
      :conditions => {"#{Slug.table_name}.name" => slug_names.to_a}
    }}
    base.named_scope :with_slug_scope, lambda {|slug_scope| {
      :conditions => {"#{Slug.table_name}.scope" => slug_scope}
    }}

  end

  # Finds a single record using the friendly_id, or the record's id.
  def find_one_with_friendly(id_or_name, options)

    scope = options.delete(:scope)

    return find_one_without_friendly(id_or_name, options) if id_or_name.is_a?(Fixnum)
    find_options = {:select => "#{self.table_name}.*"}
    find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)

    result = with_scope :find => find_options do
      with_slug_name(id_or_name).with_slug_scope(scope).find_initial(options)
    end

    if result
      result.finder_slug_name = id_or_name
    else
      result = find_one_without_friendly id_or_name, options
    end

    result

  end

  # Finds multiple records using the friendly_ids, or the records' ids.
  def find_some_with_friendly(ids_and_names, options)
    slugs = Slug.find_all_by_names_and_sluggable_type ids_and_names, base_class.name

    # separate ids and slug names
    names = slugs.map { |s| s[:name] }
    ids   = ids_and_names - names

    # search in slugs and own table
    results = []

    scope = options.delete(:scope)

    find_options = {:select => "#{self.table_name}.*"}
    find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)

    unless names.empty?
      results += with_scope(:find => find_options) do
        with_slug_name(ids_and_names).with_slug_scope(scope).find_every options
      end
    end

    unless ids.empty?
      find_options[:conditions] = {"#{table_name}.#{primary_key}" => ids}
      results += with_scope(:find => find_options) do
         find_every options
      end
    end

    # calculate expected size, taken from active_record/base.rb
    expected_size = options[:offset] ? ids_and_names.size - options[:offset] : ids_and_names.size
    expected_size = options[:limit] if options[:limit] && expected_size > options[:limit]

    if results.size != expected_size
      raise ActiveRecord::RecordNotFound, "Couldn't find all #{ name.pluralize } with IDs (#{ ids_and_names * ', ' }) AND #{ sanitize_sql options[:conditions] } (found #{ results.size } results, but was looking for #{ expected_size })"
    end

    # assign finder slugs
    slugs.each do |slug|
      results.select { |r| r.id == slug.sluggable_id }.each do |result|
        result.send(:finder_slug=, slug)
      end
    end
    results
  end

  def validate_find_options_with_friendly(options) #:nodoc:
    options.assert_valid_keys([:conditions, :include, :joins, :limit, :offset,
      :order, :select, :readonly, :group, :from, :lock, :having, :scope])
  end

end
