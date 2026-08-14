# frozen_string_literal: true

module HanamiApp
  module Relations
    # Exercises :history and :scoped together against the relation and table that
    # `hanami generate friendly_id` produces.
    class Articles < Hanami::DB::Relation
      schema :articles, infer: true

      use :friendly_id,
        base: :title,
        use: %i[history scoped],
        scope: :section_id,
        sluggable_type: "Article"
    end
  end
end
