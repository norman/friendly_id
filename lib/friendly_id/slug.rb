# A Slug is a unique, human-friendly identifier for an ActiveRecord.
class Slug < ActiveRecord::Base

  belongs_to :sluggable, :polymorphic => true
  before_save :check_for_blank_name, :set_sequence

  class << self

    # Sanitizes and dasherizes string to make it safe for URL's.
    #
    # Example:
    #
    #   slug.normalize('This... is an example!') # => "this-is-an-example"
    #
    # Note that the Unicode handling in ActiveSupport may fail to process some
    # characters from Polish, Icelandic and other languages.
    def normalize(slug_text)
      warn("Slug#normalize is deprecated and will be removed in FriendlyId 3.0. Please use SlugString#normalize.")
      raise SlugGenerationError if slug_text.blank?
      SlugString.new(slug_text.to_s).normalize.to_s
    end

    def parse(friendly_id)
      name, sequence = friendly_id.split('--')
      sequence ||= "1"
      return name, sequence
    end

    # Remove diacritics (accents, umlauts, etc.) from the string. Borrowed
    # from "The Ruby Way."
    def strip_diacritics(string)
      warn("Slug#strip_diacritics is deprecated and will be removed in FriendlyId 3.0. Please use SlugString#approximate_ascii.")
      raise SlugGenerationError if string.blank?
      SlugString.new(string).approximate_ascii
    end

    # Remove non-ascii characters from the string.
    def strip_non_ascii(string)
      raise SlugGenerationError if string.blank?
      strip_diacritics(string).gsub(/[^a-z0-9]+/i, ' ')
    end

    private

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
  def check_for_blank_name #:nodoc:#
    if name.blank?
      raise FriendlyId::SlugGenerationError.new("The slug text is blank.")
    end
  end

  def set_sequence
    return unless new_record?
    last = Slug.find(:first, :conditions => { :name => name, :scope => scope,
      :sluggable_type => sluggable_type}, :order => "sequence DESC",
      :select => 'sequence')
    self.sequence = last.sequence + 1 if last
  end

end
