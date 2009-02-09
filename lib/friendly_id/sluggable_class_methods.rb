module FriendlyId::SluggableClassMethods

  include FriendlyId::Helpers

  def self.extended(base) #:nodoc:#

    class << base
      alias_method_chain :find_one, :friendly
      alias_method_chain :find_some, :friendly
      alias_method_chain :validate_find_options, :friendly
    end

  end

  # Finds a single record using the friendly id, or the record's id.
  def find_one_with_friendly(id_or_name, options) #:nodoc:#

    scope = options.delete(:scope)
    return find_one_without_friendly(id_or_name, options) if id_or_name.is_a?(Fixnum)

    find_options = {:select => "#{self.table_name}.*"}
    find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)

    name, sequence = Slug.parse(id_or_name)

    find_options[:conditions] = {
      "#{Slug.table_name}.name"     => name,
      "#{Slug.table_name}.scope"    => scope,
      "#{Slug.table_name}.sequence" => sequence
    }

    result = with_scope(:find => find_options) { find_initial(options) }

    if result
      result.finder_slug_name = id_or_name
    else
      result = find_one_without_friendly id_or_name, options
    end

    result
  rescue ActiveRecord::RecordNotFound => e

    if friendly_id_options[:scope]
      if !scope
        e.message << "; expected scope but got none"
      else
        e.message << " and scope=#{scope}"
      end
    end

    raise e

  end

  # Finds multiple records using the friendly ids, or the records' ids.
  def find_some_with_friendly(ids_and_names, options) #:nodoc:#

    slugs, ids = get_slugs_and_ids(ids_and_names, options)
    results = []

    find_options = {:select => "#{self.table_name}.*"}
    find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)
    find_options[:conditions] = "#{quoted_table_name}.#{primary_key} IN (#{ids.empty? ? 'NULL' : ids.join(',')}) "
    find_options[:conditions] << "OR slugs.id IN (#{slugs.to_s(:db)})"

    results = with_scope(:find => find_options) { find_every(options) }

    expected = expected_size(ids_and_names, options)
    if results.size != expected
      raise ActiveRecord::RecordNotFound, "Couldn't find all #{ name.pluralize } with IDs (#{ ids_and_names * ', ' }) AND #{ sanitize_sql options[:conditions] } (found #{ results.size } results, but was looking for #{ expected })"
    end

    assign_finder_slugs(slugs, results)

    results
  end

  def validate_find_options_with_friendly(options) #:nodoc:#
    options.assert_valid_keys([:conditions, :include, :joins, :limit, :offset,
      :order, :select, :readonly, :group, :from, :lock, :having, :scope])
  end

  private

  # Assign finder slugs for the results found in find_some_with_friendly
  def assign_finder_slugs(slugs, results) #:nodoc:#
    slugs.each do |slug|
      results.select { |r| r.id == slug.sluggable_id }.each do |result|
        result.send(:finder_slug=, slug)
      end
    end
  end

  # Build arrays of slugs and ids, for the find_some_with_friendly method.
  def get_slugs_and_ids(ids_and_names, options) #:nodoc:#
    scope = options.delete(:scope)
    slugs = []
    ids = []
    ids_and_names.each do |id_or_name|
      name, sequence = Slug.parse id_or_name
      slug = Slug.find(:first, :conditions => {
        :name           => name,
        :scope          => scope,
        :sequence       => sequence,
        :sluggable_type => base_class.name
      })
      # If the slug was found, add it to the array for later use. If not, and
      # the id_or_name is a number, assume that it is a regular record id.
      slug ? slugs << slug : (ids << id_or_name if id_or_name =~ /\A\d*\z/)
    end
    return slugs, ids
  end

end