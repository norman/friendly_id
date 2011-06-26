class FriendlyIdSlug < ActiveRecord::Base
  belongs_to :sluggable, :polymorphic => true
end
