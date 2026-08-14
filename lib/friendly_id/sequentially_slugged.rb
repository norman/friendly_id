require_relative "sequentially_slugged/calculator"

module FriendlyId
  module SequentiallySlugged
    def self.setup(model_class)
      model_class.friendly_id_config.use :slugged
      model_class.friendly_id_config.instance_eval do
        self.class.send :include, Configuration
        defaults[:sequence_calculator] ||= FriendlyId::SequenceCalculator.new
      end
    end

    def resolve_friendly_id_conflict(candidate_slugs)
      candidate = candidate_slugs.first
      return if candidate.nil?

      conflicts = Calculator.new(
        scope_for_slug_generator,
        candidate,
        slug_column,
        friendly_id_config.sequence_separator,
        slug_base_class
      ).slug_conflicts

      friendly_id_config.sequence_calculator.call(
        candidate, conflicts, separator: friendly_id_config.sequence_separator
      )
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

    # This module adds the `:sequence_calculator` configuration option to
    # {FriendlyId::Configuration FriendlyId::Configuration}.
    module Configuration
      attr_writer :sequence_calculator

      # The object that decides which sequence a conflicting slug gets.
      #
      # It is sent `call(slug, conflicts, separator:)`, where `conflicts` are
      # the slugs already in the table that could carry a sequence, and returns
      # the slug to use.
      #
      #     friendly_id :name, use: :sequentially_slugged do |config|
      #       config.sequence_calculator = MyCalculator.new
      #     end
      #
      # @return [#call] The calculator. Defaults to
      #   {FriendlyId::SequenceCalculator}.
      def sequence_calculator
        @sequence_calculator ||= defaults[:sequence_calculator]
      end
    end
  end
end
