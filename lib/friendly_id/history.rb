require "friendly_id/slug"

module FriendlyId

=begin
This module adds the ability to store a log of a model's slugs, so that when its
friendly id changes, it's still possible to perform finds by the old id.

The primary use case for this is avoiding broken URLs.

== Setup

In order to use this module, you must add a table to your database schema to
store the slug records. FriendlyId provides a generator for this purpose:

  rails generate friendly_id
  rake db:migrate

This will add a table named +friendly_id_slugs+, used by the {FriendlyId::Slug}
model.

== Considerations

This module is incompatible with the +:scoped+ module.

Because recording slug history requires creating additional database records,
this module has an impact on the performance of the associated model's +create+
method.

== Example

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
        # a 301 redirect that uses the current friendly id.
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
        @friendly_id_config.use :slugged
        has_many :slugs, :as => :sluggable, :dependent => :destroy, :class_name => Slug.to_s
        before_save :build_slug, :if => lambda {|r| r.should_generate_new_friendly_id?}
        scope :with_friendly_id, lambda {|id| includes(:slugs).where("#{Slug.table_name}.slug" => id)}
        extend Finder
      end
    end

    private

    def build_slug
      slugs.build :slug => friendly_id
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