# A Slug is a unique, human-friendly identifier for an ActiveRecord.
class Slug < ActiveRecord::Base

  belongs_to :sluggable, :polymorphic => true
  validates_uniqueness_of :name, :scope => [:sluggable_type, :scope, :sequence]
  before_create :set_sequence

  class << self

    def find_all_by_names_and_sluggable_type(names, type)
      find :all, :conditions => {:name => names.to_a, :sluggable_type => type.to_s}
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
      return "" if slug_text.blank?
      s = slug_text.clone
      s.gsub!(/[\?`^~‘’'“”",.;:&]/, '')
      s.gsub!(/\W+/, ' ')
      s.strip!
      s.downcase!
      s.gsub!(/\s+/, '-')
      s.gsub(/-\z/, '')
    end

    def parse(friendly_id)
      name, sequence = friendly_id.split(/--/)
      sequence ||= 1
      return name, sequence
    end

    # Remove diacritics from the string, converting Western European strings
    # to ASCII. For example:
    #
    #   Slug::strip_diacritics("lingüística") # returns "linguistica"
    #
    # Don't bother trying this with strings in Russian, Hebrew, Japanese, etc.
    # It only works for strings that use some variation of the Roman alphabet.
    def strip_diacritics(string)
      Iconv.new('ascii//ignore//translit', 'utf-8').iconv normalize(string)
    end

  end

  # Whether or not this slug is the most recent of its owner's slugs.
  def is_most_recent?
    sluggable.slug == self
  end

  def to_friendly_id
    sequence > 1 ? "#{name}--#{sequence}" : name
  end

  protected

  # Raise a FriendlyId::SlugGenerationError if the slug name is blank.
  def validate
    if name.blank?
      raise FriendlyId::SlugGenerationError.new("The slug text is blank.")
    end
  end

  private

  def set_sequence
    last = Slug.find(:first, :conditions => { :name => name, :scope => scope,
      :sluggable_type => sluggable_type}, :order => "sequence DESC",
      :select => 'sequence')
    self.sequence = last.sequence + 1 if last
  end


end
