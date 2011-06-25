require "friendly_id/base"
require "friendly_id/model"
require "friendly_id/object_utils"
require "friendly_id/configuration"
require "friendly_id/finder_methods"

# FriendlyId is a comprehensive Ruby library for ActiveRecord permalinks and
# slugs.
# @author Norman Clarke
module FriendlyId
  autoload :Slugged,  "friendly_id/slugged"
  autoload :Scoped,   "friendly_id/scoped"
  autoload :History,  "friendly_id/history"
end
