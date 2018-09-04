module FriendlyId
  # A FriendlyId slug stored in an external table.
  #
  # @see FriendlyId::History
  class Slug < ActiveRecord::Base
    belongs_to :sluggable, :polymorphic => true

    before_save :set_scope, unless: :uses_scoped_module?

    def sluggable
      sluggable_type.constantize.unscoped { super }
    end

    def to_param
      slug
    end

    private

    def set_scope
      self.scope = sluggable_type
    end

    def uses_scoped_module?
      sluggable.class.friendly_id_config.uses?(:scoped)
    end
  end
end
