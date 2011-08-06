# A FriendlyId slug stored in an external table.
#
# @see FriendlyId::History
class FriendlyIdSlug < ActiveRecord::Base
  belongs_to :sluggable, :polymorphic => true
end
