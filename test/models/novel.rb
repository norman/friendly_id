class Novel < Book
  has_friendly_id :title, :use_slug => true
end