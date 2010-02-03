module FriendlyId
  module Sequel
    class Slug < ::Sequel::Model(:slugs)

      def to_friendly_id
        sequence > 1 ? friendly_id_with_sequence : name
      end

      private

      def before_create
        self.sequence = next_sequence
        self.created_at = DateTime.now
      end

      def enable_name_reversion
        conditions = { :sluggable_id => sluggable_id, :sluggable_type => sluggable_type,
            :name => name, :scope => scope }
        self.class.filter(conditions).delete
      end

      def friendly_id_with_sequence
        "#{name}#{separator}#{sequence}"
      end

      def next_sequence
        enable_name_reversion
        conditions =  { :name => name, :scope => scope, :sluggable_type => sluggable_type }
        prev = self.class.filter(conditions).order("sequence DESC").first
        prev ? prev.sequence.succ : 1
      end

      def separator
        sluggable_type.constantize.friendly_id_config.sequence_separator
      end

    end
  end
end