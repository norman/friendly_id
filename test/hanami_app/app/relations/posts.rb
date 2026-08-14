# frozen_string_literal: true

module HanamiApp
  module Relations
    class Posts < Hanami::DB::Relation
      schema :posts, infer: true

      # The Hanami counterpart of `friendly_id :title, use: :slugged` on an
      # Active Record model.
      use :friendly_id, base: :title, use: [:sequentially_slugged]
    end
  end
end
