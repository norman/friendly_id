# frozen_string_literal: true

module HanamiApp
  module Relations
    class FriendlyIdSlugs < Hanami::DB::Relation
      schema :friendly_id_slugs, infer: true
    end
  end
end
