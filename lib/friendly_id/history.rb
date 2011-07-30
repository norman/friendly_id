require "friendly_id/slug"

module FriendlyId

=begin
FriendlyId can maintain a history of your record's older slugs, so if your
record's friendly_id changes, your URL's won't break.

    class Post < ActiveRecord::Base
      extend FriendlyId
      friendly_id :title, :use => :history
    end

    class PostsController < ApplicationController

      before_filter :find_post

      ...
      def find_post
        return unless params[:id]
        @post = begin
          Post.find params[:id]
        rescue ActiveRecord::RecordNotFound
          Post.find_by_friendly_id params[:id]
        end
        # If an old id or a numeric id was used to find the record, then
        # the request path will not match the post_path, and we should do
        # a 301 redirect that uses the current friendly_id
        if request.path != post_path(@post)
          return redirect_to @post, :status => :moved_permanently
        end
      end
    end
=end
  module History

    # Configures the model instance to use the History add-on.
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

  # Adds a finder that explictly uses slugs from the slug table.
  module Finder

    # Search for a record in the slugs table using the specified slug.
    def find_by_friendly_id(*args)
      with_friendly_id(args.shift).first(*args)
    end
  end
end