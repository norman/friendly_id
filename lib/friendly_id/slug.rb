module FriendlyId
  # A FriendlyId slug stored in an external table.
  #
  # @see FriendlyId::History
  class Slug < ActiveRecord::Base
    self.table_name = "friendly_id_slugs"
    belongs_to :sluggable, :polymorphic => true

    def to_param
      slug
    end

  end
end
