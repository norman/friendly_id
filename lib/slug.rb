# A Slug is a unique, human-friendly identifier for an ActiveRecord.
class Slug < ActiveRecord::Base

  belongs_to :sluggable, :polymorphic => true
  validates_uniqueness_of :name, :scope => :sluggable_type

  class << self
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
    def normalize(slug_text)
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
      Iconv.new('ascii//ignore//translit', 'utf-8').
      iconv ActiveSupport::Multibyte::Handlers::UTF8Handler.normalize(string)
    end

  end

  # Whether or not this slug is the most recent of its owner's slugs.
  def is_most_recent?
    sluggable.slug == self
  end

  def self.include_sluggable(includes, includable = :sluggable)
    case includes
    when nil;   includable
    when Array; includes | includable
    else
      "#{ includes }" != "#{ includable }" ?
      [ includes, includable ] :
      includable
    end
  end

end
