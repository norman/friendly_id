module FriendlyId
  module Sequel

    module SluggedModel

      def self.included(base)
        base.one_to_many :slugs, :class => FriendlyId::Sequel::Slug, :key => "sluggable_id"
      end

      private

      def build_slug
        @new_slug = FriendlyId::Sequel::Slug.new :name => "hello world"
      end

      def validate
        build_slug
      end

    end
  end
end