# frozen_string_literal: true

module HanamiApp
  module Relations
    class Authors < Hanami::DB::Relation
      schema :authors, infer: true

      # No :sequentially_slugged, so conflicts get a UUID instead.
      use :friendly_id, base: :name, reserved_words: %w[new edit admin]
    end
  end
end
