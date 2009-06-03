#encoding: utf-8

# A Slug is a unique, human-friendly identifier for an ActiveRecord.
class Slug < ActiveRecord::Base

  belongs_to :sluggable, :polymorphic => true
  before_save :check_for_blank_name, :set_sequence
  
  
  ASCII_APPROXIMATIONS = {
    198 => "AE",
    208 => "D",
    216 => "O",
    222 => "Th",
    223 => "ss",
    230 => "ae",
    240 => "d",
    248 => "o",
    254 => "th"
  }.freeze

  class << self

    # Sanitizes and dasherizes string to make it safe for URL's.
    #
    # Example:
    #
    #   slug.normalize('This... is an example!') # => "this-is-an-example"
    #
    # Note that the Unicode handling in ActiveSupport may fail to process some
    # characters from Polish, Icelandic and other languages. If your
    # application uses these languages, check {out this
    # article}[http://link-coming-soon.com] for information on how to get
    # better urls in your application.
    def normalize(slug_text)
      return "" if slug_text.nil? || slug_text == ""
      ActiveSupport::Multibyte.proxy_class.new(slug_text.to_s).normalize(:kc).
        gsub(/[\W]/u, ' ').
        strip.
        gsub(/\s+/u, '-').
        gsub(/-\z/u, '').
        downcase.
        to_s
    end
    
    def parse(friendly_id)
      name, sequence = friendly_id.split('--')
      sequence ||= "1"
      return name, sequence
    end

    # Remove diacritics (accents, umlauts, etc.) from the string. Borrowed
    # from "The Ruby Way."
    def strip_diacritics(string)
      ActiveSupport::Multibyte.proxy_class.new(string).normalize(:kd).unpack('U*').inject([]) { |a, u| 
        if ASCII_APPROXIMATIONS[u]
          a += ASCII_APPROXIMATIONS[u].unpack('U*')
        elsif (u < 0x300 || u > 0x036F)
          a << u
        end
        a
      }.pack('U*')
    end


    
    # Remove non-ascii characters from the string.
    def strip_non_ascii(string)
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