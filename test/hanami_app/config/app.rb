# frozen_string_literal: true

require "hanami"

# FriendlyId's ROM adapter registers a relation plugin, so it has to be loaded
# before any relation class calls `use :friendly_id`.
require "friendly_id/hanami"

module HanamiApp
  class App < Hanami::App
  end
end
