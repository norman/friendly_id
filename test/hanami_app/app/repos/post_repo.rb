# frozen_string_literal: true

module HanamiApp
  module Repos
    # The explicit `[:posts]` is required: Hanami::DB::Repo's root inference
    # does not apply to its direct subclasses, so a bare `< Hanami::DB::Repo`
    # leaves `root` nil and FriendlyId has no relation to work with.
    class PostRepo < Hanami::DB::Repo[:posts]
      include FriendlyId::Rom::Repo

      def find_by_slug!(slug) = posts.friendly.by_friendly_id(slug).one!
      def all_slugs = posts.pluck(:slug)
    end
  end
end
