# FriendlyId Guide

* Table of Contents
{:toc}

## Overview

FriendlyId is an ORM-centric Ruby library that lets you work with human-friendly
strings as if they were numeric ids. Among other things, this facilitates
replacing "unfriendly" URL's like:

    http://example.com/states/4323454

with "friendly" ones such as:

    http://example.com/states/washington

FriendlyId is typically used with Rails and Active Record, but can also be used in
non-Rails applications.

## Simple Models

The simplest way to use FriendlyId is with a model that has a uniquely indexed
column with no spaces or special characters, and that is seldom or never
updated. The most common example of this is a user name or login column:

    class User < ActiveRecord::Base
      validates_format_of :login, :with => /\A[a-z0-9]+\z/i
      has_friendly_id :login
    end

    @user = User.find "joe"   # the old User.find(1) still works, too
    @user.to_param            # returns "joe"
    redirect_to @user         # the URL will be /users/joe

In this case, FriendlyId assumes you want to use the column as-is; it will never
modify the value of the column, and your application should ensure that the value
is admissible in a URL:

    class City < ActiveRecord::Base
      has_friendly_id :name
    end

    @city.find "Viña del Mar"
    redirect_to @city # the URL will be /cities/Viña%20del%20Mar

For this reason, it is often more convenient to use Slugs rather than a single
column.

## Slugged Models

FriendlyId uses a separate column to store slugs for models which require some
processing of the friendly_id text. The most common example is a blog post's
title, which may have spaces, uppercase characters, or other attributes you
wish to modify to make them more suitable for use in URL's.

    class Post < ActiveRecord::Base
      include FriendlyId::Slugged
      has_friendly_id :title
    end

    @post = Post.create(:title => "This is the first post!")
    @post.friendly_id   # returns "this-is-the-first-post"
    redirect_to @post   # the URL will be /posts/this-is-the-first-post

If you are unsure whether to use slugs, then your best bet is to use them,
because FriendlyId provides many useful features that only work with this
feature. These features are explained in detail {file:Guide.md#features below}.

## Installation

    gem install friendly_id

After installing the gem, add an entry in the Gemfile:

    gem "friendly_id", "~> 4.0.0"

### Future Compatibility

FriendlyId will always remain compatible with the current release of Rails, and
at least one stable release behind. That means that support for 3.0.x will not be
dropped until a stable release of 3.2 is out, or possibly longer.

## Configuration

FriendlyId is configured in your model using the `has_friendly_id` method. Additional
features can be activated by including various modules:

    class Post < ActiveRecord::Base
      # use slugs
      include FriendlyId::Slugged
      # record slug history
      include FriendlyId::History
      # use the "title" accessor as the basis of the friendly_id
      has_friendly_id :title
    end

Read on to learn about the various features that can be configured. For the
full list of valid configuration options, see the instance attribute summary
for {FriendlyId::Configuration}.

# Features

## FriendlyId Strings

By default, FriendlyId uses Active Support's Transliterator class to convert strings into
ASCII slugs by default. Please see the API docs for
[transliterate](http://api.rubyonrails.org/) and
[parameterize](http://api.rubyonrails.org/) to see what options are avaialable
to you.

Previous versions of FriendlyId used [Babosa](github.com/norman/babosa) for slug
string handling, but the core functionality it provides was extracted from it
and added to Rails 3. However, Babosa offers some advanced functionality not
offered by Rails and can still be a convenient option. This section shows how
you can use it with FriendlyId.

### Using a Custom Method to Generate the Slug Text

FriendlyId can use either a column or a method to generate the slug text for
your model:

    class City < ActiveRecord::Base

      belongs_to :country
      has_friendly_id :name_and_country, :use_slug => true

      def name_and_country
        #{name} #{country.name}
      end

    end

    @country = Country.create(:name => "Argentina")
    @city = City.create(:name => "Buenos Aires", :country => @country)
    @city.friendly_id # will be "buenos-aires-argentina"

One word of caution: in the example above, if the country's name were updated,
say, to "Argentine Republic", the city's friendly_id would not be
automatically updated. For this reason, it's a good idea to avoid using
frequently-updated relations as a part of the friendly_id.

## Using a Custom Method to Process the Slug Text

If the built-in slug text handling options don't work for your application,
you can override the `normalize_friendly_id` method in your model class in
order to fine-tune the output:

    class City < ActiveRecord::Base

      def normalize_friendly_id(text)
        my_text_modifier_method(text)
      end

    end

The normalize_friendly_id method takes a single argument and receives an
instance of {FriendlyId::SlugString}, a class which wraps a regular Ruby string
with additional formatting options.

### Converting non-Latin characters to ASCII with Babosa

Babosa offers the ability to idiomatically transliterate non-ASCII characters
to ASCII:

    "Jürgen".to_slug.normalize!                           #=> "Jurgen"
    "Jürgen".to_slug.normalize! :transliterate => :german #=> "Juergen"

Using Babosa with FriendlyId is a simple matter of installing and requiring
the `babosa` gem, and overriding the `normalize_friendly_id` method in your
model:

    class City < ActiveRecord::Base
      def normalize_friendly_id(text)
        text.slug.normalize!
      end
    end

## Redirecting to the Current Friendly URL

FriendlyId can maintain a history of your record's older slugs, so if your
record's friendly_id changes, your URL's won't break.

    class Post < ActiveRecord::Base
      include FriendlyId::Slugged
      include FriendlyId::History
      has_friendly_id :title
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

## Non-unique Slugs

FriendlyId will append a arbitrary number to the end of the id to keep it
unique if necessary:

    /posts/new-version-released
    /posts/new-version-released--2
    /posts/new-version-released--3
    ...
    etc.

Note that the number is preceded by "--" rather than "-" to distinguish it from
the rest of the slug. This is important to enable having slugs like:

    /cars/peugeot-206
    /cars/peugeot-206--2

You can configure the separator string used by your model by setting the
`:sequence_separator` option in `has_friendly_id`:

    has_friendly_id :title, :use_slug => true, :sequence_separator => ":"

You can also override the default used in
{FriendlyId::Configuration::DEFAULTS} to set the value for any model using
FriendlyId. If you change this value in an existing application, be sure to
{file:Guide.md#regenerating_slugs regenerate the slugs} afterwards.

For reasons I hope are obvious, you can't change this value to "-". If you try,
FriendlyId will raise an error.

## Reserved Words

You can configure a list of strings as reserved so that, for example, you
don't end up with this problem:

    /users/joe-schmoe # A user chose "joe schmoe" as his user name - no worries.
    /users/new        # A user chose "new" as his user name, and now no one can sign up.

Reserved words are configured using the `:reserved_words` option:

    class Restaurant < ActiveRecord::Base
      belongs_to :city
      has_friendly_id :name, :use_slug => true, :reserved_words => ["my", "values"]
    end

The reserved words can be specified as an array or (since 3.1.7) as a regular
expression.

The strings "new" and "index" are reserved by default. When you attempt to
store a reserved value, FriendlyId raises a
{FriendlyId::ReservedError}. You can also override the default
reserved words in {FriendlyId::Configuration::DEFAULTS} to set the value for any
model using FriendlyId.

If you'd like to show a validation error when a word is reserved, you can add
an callback to your model that catches the error:

    class Person < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true

      after_validation :validate_reserved

      def validate_reserved
        slug_text
      rescue FriendlyId::ReservedError
        @errors[friendly_id_config.method] = "is reserved. Please choose something else"
        return false
      end
    end

## Scoped Slugs

FriendlyId can generate unique slugs within a given scope. For example, assume
you have an application that displays restaurants. Without scoped slugs, if two
restaurants are named "Joe's Diner," the second one will end up with
"joes-diner--2" as its friendly_id. Using scoped allows you to keep the slug
names unique for each city, so that the second "Joe's Diner" can also have the
slug "joes-diner", as long as it's located in a different city:

    class Restaurant < ActiveRecord::Base
      belongs_to :city
      include FriendlyId::Slugged
      include FriendlyId::Scoped
      has_friendly_id :name, :scope => :city
    end

    class City < ActiveRecord::Base
      has_many :restaurants
      include FriendlyId::Slugged
      has_friendly_id :name
    end

    City.find("seattle").restaurants.find("joes-diner")
    City.find("chicago").restaurants.find("joes-diner")


The value for the `:scope` key in your model can be a column, or the name of a
relation.

### Complications with Scoped Slugs

#### Finding Records by friendly\_id

If you are using scopes your friendly ids may not be unique, so a simple find like

    Restaurant.find("joes-diner")

may return the wrong record. In these cases when you want to use the friendly\_id for queries,
either query as a relation, or specify the scope in your query conditions:

    # will only return restaurants named "Joe's Diner" in the given city
    @city.restaurants.find("joes-diner")

    # or

    Restaurants.find("joes-diner").where(:city_id => @city.id)


#### Finding All Records That Match a Scoped ID

If you want to find all records with a particular friendly\_id regardless of scope,
the easiest way is to use cached slugs and query this column directly:

    Restaurant.find_all_by_slug("joes-diner")

### Routes for Scoped Models

Note that FriendlyId does not set up any routes for scoped models; you must do
this yourself in your application. Here's an example of one way to set this up:

    # in routes.rb
    resources :cities do
      resources :restaurants
    end

    # in views
    <%= link_to 'Show', [@city, @restaurant] %>

    # in controllers
    @city = City.find(params[:city_id])
    @restaurant = @city.restaurants.find(params[:id])

    # URL's:
    http://example.org/cities/seattle/restaurants/joes-diner
    http://example.org/cities/chicago/restaurants/joes-diner


# Misc tips

## Allowing Users to Override/Control Slugs

Would you like to mostly use default slugs, but allow the option of a
custom user-chosen slug in your application? If so, then you're not the first to
want this. Here's a [demo
application](http://github.com/norman/friendly_id_manual_slug_demo) showing how
it can be done.

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

    activerecord (3.0.9)
    ruby 1.9.2p180 (2011-02-18 revision 30909) [x86_64-darwin10.6.0]
    friendly_id (4.0.0.pre3)
    sqlite3 (1.3.3) gem
    sqlite3 3.6.12 in-memory database

                                  user     system      total        real
    find (without FriendlyId)     0.280000   0.000000   0.280000 (  0.278086)
    find (in-table slug)          0.320000   0.000000   0.320000 (  0.320151)
    find (external slug)          3.040000   0.010000   3.050000 (  3.048054)
    insert (without FriendlyId)   0.780000   0.000000   0.780000 (  0.785427)
    insert (in-table-slug)        1.520000   0.010000   1.530000 (  1.532350)
    insert (external slug)        3.310000   0.020000   3.330000 (  3.335548)