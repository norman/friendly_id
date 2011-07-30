require "friendly_id/slug"

module FriendlyId
  module History

    def self.included(klass)
      klass.instance_eval do
        raise "FriendlyId::History is incompatibe with FriendlyId::Scoped" if self < Scoped
        include Slugged unless self < Slugged
        has_many :friendly_id_slugs, :as => :sluggable, :dependent => :destroy
        before_save :build_friendly_id_slug, :if => lambda {|r| r.slug_sequencer.slug_changed?}
        scope :with_friendly_id, lambda {|id| includes(:friendly_id_slugs).where("friendly_id_slugs.slug = ?", id)}
        extend Finder
      end
    end

    private

    def build_friendly_id_slug
      self.friendly_id_slugs.build :slug => friendly_id
    end
  end

  module Finder
    def find_by_friendly_id(*args)
      with_friendly_id(args.shift).first(*args)
    end
  end
end