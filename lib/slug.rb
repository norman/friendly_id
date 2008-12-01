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

    # Checks a slug name for collisions
    def get_best_name(name, type)
      slugs = find :all, :conditions => ['name LIKE ? AND sluggable_type = ?', "#{name}%", type.to_s], :select => "name"
      return name if slugs.size == 0
      slugs.reject! { |x| x.base != name }
      slugs.sort! { |x, y| x.extension <=> y.extension }
      slugs.empty? ? name : slugs.last.succ
    end

    # Sanitizes and dasherizes string to make it safe for URL's.
    #
    # Example:
    #
    #   slug.normalize('This... is an example!') # => "this-is-an-example"
    #
    # Note that Rails 2.2.x offers a parameterize method for this. It's not
    # used here because at the time of writing, it handles several characters
    # incorrectly, for instance replacing Icelandic's "thorn" character with
    # "y" rather than "d." This might be pedantic, but I don't want to piss
    # off the Vikings. The last time anyone pissed them off, they uleashed a
    # wave of terror in Europe unlike anything ever seen before or after. I'm
    # not taking any chances.
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

  def succ
    "#{base}-#{extension == 0 ? 2 : extension.succ}"
  end

  def base
    name.gsub(/-?\d*\z/, '')
  end

  def extension
    /\d*\z/.match(name).to_s.to_i
  end

  # Whether or not this slug is the most recent of its owner's slugs.
  def is_most_recent?
    sluggable.slug == self
  end
end
