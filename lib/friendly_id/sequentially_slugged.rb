require_relative 'sequentially_slugged/calculator'

module FriendlyId
  module SequentiallySlugged
    def self.setup(model_class)
      model_class.friendly_id_config.use :slugged
    end

    def resolve_friendly_id_conflict(candidate_slugs)
      candidate = candidate_slugs.first
      return if candidate.nil?

      Calculator.new(
        scope_for_slug_generator,
        candidate,
        slug_column,
        friendly_id_config.sequence_separator,
        slug_base_class
      ).next_slug
    end

    private

    def slug_base_class
      if friendly_id_config.uses?(:history)
        Slug
      else
        self.class.base_class
      end
    end

    def slug_column
      if friendly_id_config.uses?(:history)
        :slug
      else
        friendly_id_config.slug_column
      end
    end
  end
end
