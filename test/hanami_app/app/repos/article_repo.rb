# frozen_string_literal: true

module HanamiApp
  module Repos
    class ArticleRepo < Hanami::DB::Repo[:articles]
      include FriendlyId::Rom::Repo
    end
  end
end
