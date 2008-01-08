class Slug < ActiveRecord::Base

  belongs_to :sluggable, :polymorphic => true
  validates_uniqueness_of :name, :scope => :sluggable_type
  
   def self.count_matches(slug_text, sluggable_type, *args)
    slugs = with_scope({:find => {:conditions => ["slugs.name LIKE '#{slug_text}%' AND sluggable_type = ?", 
        sluggable_type]}}) do
      find(*args)
    end
    count = 0
    slugs.each do |slug|
      count = count + 1 if slug.name =~ /\A#{slug_text}(-[\d]+)*\Z/
    end
    return count
  end
  
  def is_most_recent?
    sluggable.slug == self
  end
  
  def self.normalize(slug_text)
    slug_text.gsub!(/\W+/, ' ')
    slug_text.strip!
    slug_text.downcase!
    slug_text.gsub!(/\s+/, '-')
    slug_text.gsub(/-\Z/, '')
  end
  
end