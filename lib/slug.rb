# A Slug is a unique, human-friendly identifier for an ActiveRecord.
class Slug < ActiveRecord::Base

  belongs_to :sluggable, :polymorphic => true
  validates_uniqueness_of :name, :scope => :sluggable_type

  class << self
    def with_name(name)
      "#{ quoted_table_name }.name = #{ quote_value name, columns_hash['name'] }"
    end
    def with_names(names)
      name_column = columns_hash['name']
      names = names.map { |n| "#{ quote_value n, name_column }" }.join ','

      "#{ quoted_table_name }.name IN (#{ names })"
    end
    def find_all_by_names_and_sluggable_type(names, type)
      names = with_names names
      type  = "#{ quoted_table_name }.sluggable_type = #{ quote_value type, columns_hash['sluggable_type'] }"
      find :all, :conditions => "#{ names } AND #{ type }"
    end

    # Count exact matches for a slug. Matches include slugs with the same name
    # and an appended numeric suffix, i.e., "an-example-slug" and
    # "an-example-slug-2"
    #
    # The first two arguments are required, after which you may pass in the
    # same arguments as ActiveRecord::Base.find.
    COND = 'name LIKE ? AND sluggable_type = ?'.freeze
    def count_matches(name, type, *args)
      name_esc = Regexp.escape name

      with_scope(:find => {:conditions => [COND, "#{name}%", type]}) {
        find(*args)
      }.inject(0) do |count, slug|
        slug.name =~ /\A#{name_esc}(-[\d]+)*\Z/ ? count + 1 : count
      end
    end

    # Sanitizes and dasherizes string to make it safe for URL's.
    #
    # Example:
    #   slug.normalize('This... is an example!') # => "this-is-an-example"
    #
    # Note that Rails 2.2.x offers a parameterize method for stripping
    # diacritics. This is not used here because at the time of writing, it
    # handles several characters incorrectly, for instance replacing
    # Icelandic's "thorn" character with "y" rather than "d." This might be
    # pedantic, but I don't want to piss off the Vikings. The last time anyone
    # pissed them off, they uleashed a wave of terror in Europe unlike
    # anything ever seen before or after. I'm not taking any chances.
    def normalize(slug_text)
      # Use this onces it starts working reliably
      # return slug_text.parameterize.to_s if slug_text.respond_to?(:parameterize)
      s = slug_text.clone
      s.gsub!(/[\?`^~‘’'“”",.;:]/, '')
      s.gsub!(/&/, 'and')
      s.gsub!(/\W+/, ' ')
      s.strip!
      s.downcase!
      s.gsub!(/\s+/, '-')
      s.gsub(/-\Z/, '')
    end

    # Remove diacritics from the string.
    def strip_diacritics(string)
      Iconv.new('ascii//ignore//translit', 'utf-8').iconv normalize(string)
    end

  end

  # Whether or not this slug is the most recent of its owner's slugs.
  def is_most_recent?
    debugger
    sluggable.slug == self
  end

end
