# FriendlyId Guide

* Table of Contents
{:toc}

## Installation

    gem install friendly_id

After installing the gem, add an entry in the Gemfile:

    gem "friendly_id", "~> 4.0.0"

### Future Compatibility

FriendlyId will always remain compatible with the current release of Rails, and
at least one stable release behind. That means that support for 3.0.x will not be
dropped until a stable release of 3.2 is out, or possibly longer.

## Redirecting to the Current Friendly URL

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

# Misc tips

## Default Scopes

Whether you're using FriendlyId or not, a good rule of thumb for default scopes
is to always use your model's table name. Otherwise any time you do a join, you
risk having queries fail because of duplicate column names - particularly for a
default scope like this one:

    default_scope :order => "created_at DESC"

Instead, do this:

    default_scope :order => = "#{quoted_table_name}.created_at DESC"

Or even better, unless you're using a custom primary key:

    default_scope :order => = "#{quoted_table_name}.id DESC"

because sorting by a unique integer column is faster than sorting by a date
column.

## Some Benchmarks

These benchmarks can give you an idea of FriendlyId's impact on the
performance of your application. Of course your results may vary.

