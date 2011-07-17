require "friendly_id/base"
require "friendly_id/model"
require "friendly_id/object_utils"
require "friendly_id/configuration"
require "friendly_id/finder_methods"

# FriendlyId is a comprehensive Ruby library for ActiveRecord permalinks and
# slugs.
#
# @author Norman Clarke
module FriendlyId
  autoload :Slugged,  "friendly_id/slugged"
  autoload :Scoped,   "friendly_id/scoped"
  autoload :History,  "friendly_id/history"

  def self.extended(base)
    base.instance_eval do
      extend FriendlyId::Base
      @friendly_id_config = Class.new(FriendlyId::Configuration).new(base)
    end
    ActiveRecord::Relation.send :include, FriendlyId::FinderMethods
  end
end
