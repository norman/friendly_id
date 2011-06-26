require "friendly_id/slug"

module FriendlyId
  module History

    def self.included(base)
      base.class_eval do
        include Slugged unless include? Slugged
        extend  Finder
        has_many :friendly_id_slugs, :as => :sluggable, :dependent => :destroy
        before_save :build_friendly_id_slug, :if => lambda {|r| r.slug_sequencer.slug_changed?}
      end
    end

    private

    def build_friendly_id_slug
      self.friendly_id_slugs.build :slug => friendly_id
    end
  end

  module Finder
    def find_by_friendly_id(*args)
      where("friendly_id_slugs.slug = ?", args.shift).includes(:friendly_id_slugs).first(*args)
    end
  end
end