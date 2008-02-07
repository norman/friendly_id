# A Slug is a unique, human-friendly identifier for an ActiveRecord.
class Slug < ActiveRecord::Base

  belongs_to :sluggable, :polymorphic => true
  validates_uniqueness_of :name, :scope => :sluggable_type
  
   # Count exact matches for a slug. Matches include slugs with the same name
   # and an appended numeric suffix, i.e., "an-example-slug" and
   # "an-example-slug-2"
   #
   # The first two arguments are required, after which you may pass in the
   # same arguments as ActiveRecord::Base.find.
   def self.count_matches(slug_text, sluggable_type, *args)
    return 0 if !Slug.find_by_name(slug_text)
    slugs = with_scope({:find => {:conditions => ["name LIKE '#{slug_text}%' AND sluggable_type = ?", 
        sluggable_type]}}) do
      find(*args)
    end
    count = 0
    slugs.each do |slug|
      puts slug.name
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
  	s = slug_text.clone
  	s.gsub!(/[\?’",.;:]/, '')
  	s.gsub!(/\W+/, ' ')
  	s.strip!
  	s.downcase!
  	s.gsub!(/\s+/, '-')
  	s.gsub(/-\Z/, '')
  end
  
end