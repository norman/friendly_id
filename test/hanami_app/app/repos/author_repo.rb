# frozen_string_literal: true

module HanamiApp
  module Repos
    class AuthorRepo < Hanami::DB::Repo[:authors]
      include FriendlyId::Rom::Repo
    end
  end
end
