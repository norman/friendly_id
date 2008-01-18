# A Slug is a unique, human-friendly identifier for an ActiveRecord.
class Slug < ActiveRecord::Base

  belongs_to :sluggable, :polymorphic => true
  validates_uniqueness_of :name, :scope => :sluggable_type
  
   # Count exact matches for a slug. Matches include slugs with the same name
   # and an appended numeric suffix, i.e., "an-example-slug" and
   # "an-example-slug-2"
   #
   # The first two arguments are required, after which you may pass in the same
   # arguments as ActiveRecord::Base::find.
   #
   def self.count_matches(slug_text, sluggable_type, *args)
    slugs = with_scope({:find => {:conditions => ["name LIKE '#{slug_text}%' AND sluggable_type = ?", 
        sluggable_type]}}) do
      find(*args)
    end
    count = 0
    slugs.each do |slug|
      count = count + 1 if slug.name =~ /\A#{slug_text}(-[\d]+)*\Z/
    end
    return count
  end
  
  # Whether or not this slug is the most recent of its owner's slugs.
  def is_most_recent?
    sluggable.slug == self
  end
  
  # Sanitizes and dasherizes string to make it safe for URL's.
  #
  # Example:
  #
  # This... is an example string!
  #
  # Becomes:
  #
  # this-is-an-example-string
  #
  def self.normalize(slug_text)
    slug_text.gsub!(/[\?'",.;:]/, '')
    slug_text.gsub!(/\W+/, ' ')
    slug_text.strip!
    slug_text.downcase!
    slug_text.gsub!(/\s+/, '-')
    slug_text.gsub(/-\Z/, '')
  end
  
end