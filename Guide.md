# FriendlyId Guide

* Table of Contents
{:toc}

## Overview

FriendlyId is a Ruby gem which allows you to work with human-friendly strings
as if they were numeric ids for ActiveRecord models. This facilitates replacing
"unfriendly" URL's like

    http://example.com/states/4323454

with "friendly" ones such as:

    http://example.com/states/washington

## Simple Models

The simplest way to use FriendlyId is with a model that has a uniquely indexed
column with no spaces or special characters, and that is seldom or never
updated. The most common example of this is a user name or login column:

    class User < ActiveRecord::Base
      :validates_format_of :login, :with => /\A[a-z0-9]\z/i
      has_friendly_id :login
    end

    @user = User.find "joe"   # the old User.find(1) still works, too
    @user.to_param            # returns "joe"
    redirect_to @user         # the URL will be /users/joe

In this case, FriendlyId assumes you want to use the column as-is; FriendlyId
will never modify the value of the column, and your application must ensure
that the value is admissible in a URL:

    class City < ActiveRecord::Base
      has_friendly_id :name
    end

    @city.find "Viña del Mar"
    redirect_to @city # the URL will be /cities/Viña%20del%20Mar

For this reason, it is often more convenient to use Slugs rather than a single
column.

## Slugged Models

FriendlyId uses a separate table to store slugs for models which require some
processing of the friendly_id text. The most common example is a blog post's
title, which may have spaces, uppercase characters, or other attributes you
wish to modify to make them more suitable for use in URL's.

    class Post < ActiveRecord::Base
      has_friendly_id :title, :use_slug => true
    end

    @post = Post.create(:title => "This is the first post!")
    @post.friendly_id   # returns "this-is-the-first-post"
    redirect_to @post   # the URL will be /posts/this-is-the-first-post

If you are unsure whether to use slugs, then your best bet is to use them,
because FriendlyId provides many useful features that only work with slugs.
These features are explained in detail {file:Guide.md#features below}.

## Installation

FriendlyId can be installed as a gem, or as a Rails plugin. It is compatible
with Rails 2.2.x, 2.3.x. Support for Rails 3.x is in progress.

### As a Gem

    gem install friendly_id

#### Rails 2.2.x - 2.3.x

After installing the gem, add an entry in environment.rb:

    config.gem "friendly_id"

#### Rails 3.x

*NOTE: Rails 3.x support is in progress and may or may not work at any given time.*

Add an entry in the `Gemfile` for `friendly_id`, and in  `config/environment.rb`, add:

    Bundler.require_env

somewhere before `Application.initialize!`.

### As a Plugin

Plugin installation is simple for all supported versions of Rails:

    ./script/plugin install git://github.com/norman/friendly_id.git

However, installing as a gem offers simpler version control than plugin
installation. Whenever possible, install as a gem instead.

### Setup

After installing either as a gem or plugin, run:

    ./script/generate friendly_id
    rake db:migrate

This will install the Rake tasks and slug migration for FriendlyId. If you are
not going to use slugs, you can do:

    ./script/generate friendly_id --skip-migration

FriendlyId is now set up and ready for you to use.

## Configuration

FriendlyId is configured in your model using the {FriendlyId#has_friendly_id} class method:

    has_friendly_id :a_column_or_method options_hash

    class Post < ActiveRecord::Base
      # use the "title" column as the basis of the friendly_id, and use slugs
      has_friendly_id :title, :use_slug => true,
        # remove accents and other diacritics from Western characters
        :approximate_ascii => true,
        # don't use slugs longer than 50 chars
        :max_length => 50
    end

For the full list of valid configuration options, see the instance attribute
summary for {FriendlyId::Configuration}.

# Features

## FriendlyId Strings

FriendlyId comes with {FriendlyId::SlugString excellent support for Unicode
strings}. When using slugs, FriendlyId will automatically modify the slug text
to make it more suitable for use in a URL:

    class City < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true
    end

    @city.create :name => "Viña del Mar"
    @city.friendly_id  # will be "viña-del-mar"

By default, the string is {FriendlyId::SlugString#downcase! downcased} and
{FriendlyId::SlugString#clean! stripped}, {FriendlyId::SlugString#with_dashes! spaces are replaced with dashes},
and {FriendlyId::SlugString#word_chars! non-word characters are removed}.

### Replacing Accented Characters

If your strings use Western characters, you can use the `:approximate_ascii` option to remove
accents and other diacritics:

    class City < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true, :approximate_ascii => true
    end

    @city.create :name => "Łódź, Poland"
    @city.friendly_id  # will be "lodz-poland"

There are special options for some languages:

### German Approximations

    class Person < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true, :approximate_ascii => true,
        :ascii_approximation_options => :german
    end

    @person.create :name => "Jürgen Müller"
    @person.friendly_id  # will be "juergen-mueller"

### Spanish Approximations

    class Post < ActiveRecord::Base
      has_friendly_id :title, :use_slug => true, :approximate_ascii => true,
        :ascii_approximation_options => :spanish
    end

    @post.create(:title => "¡Feliz año!")
    @post.title  # will be "feliz-anno"

### Approximations for Other Languages

You can add custom approximations for your language by adding Hash of
approximations to {FriendlyId::SlugString::APPROXIMATIONS}. The approximations
must be listed as Unicode decimal numbers, and arrays of numbers.

### Unicode Slugs

By default, any character outside the Unicode Western character sets will be
passed through untouched, allowing you to have slugs in Arabic, Japanese,
Greek, etc:

    @post.create :title => "katakana: ゲコゴサザシジ!"
    @post.friendly_id # will be: "katakana-ゲコゴサザシジ"

### ASCII Slugs

You can also configure FriendlyId using `:strip_non_ascii` to completely delete
any non-ascii characters:

    class Post < ActiveRecord::Base
      has_friendly_id :title, :use_slug => true, :strip_non_ascii => true
    end

    @post.create :title => "katakana: ゲコゴサザシジ!"
    @post.friendly_id # will be: "katakana"


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
instance of {FriendlyId::SlugString}, a class which wraps a regular Ruby
string with some additional formatting options inherits Multibyte support from
ActiveSupport::Multibyte::Chars.

### Converting non-Western characters to ASCII with Stringex

Stringex is a library which provides some interesting options for transliterating
non-Western strings to ASCII:

    "你好".to_url => "ni-hao"

Using Stringex with FriendlyId is a simple matter of installing and requiring
the `stringex` gem, and overriding the `normalize_friendly_id` method in your
model:

    class City < ActiveRecord::Base

      def normalize_friendly_id(text)
        text.to_url
      end

    end

## Redirecting to the Current Friendly URL

FriendlyId maintains a history of your record's older slugs, so if your
record's friendly_id changes, your URL's won't break. It offers several
methods to determine whether the model instance was found using the most
recent friendly_id. This helps you redirect to your "unfriendly" URL's to your
new "friendly" ones when adding FriendlyId to an existing application:

    class PostsController < ApplicationController

      before_filter ensure_current_post_url, :only => :show

      ...

      def ensure_current_post_url
        redirect_to @post, :status => :moved_permanently unless @post.friendly_id_status.best?
      end

    end

For more information, take a look at the documentation for {FriendlyId::Status}.

## Non-unique Slugs

FriendlyId will append a arbitrary number to the end of the id to keep it
unique if necessary:

    /posts/new-version-released
    /posts/new-version-released--2
    /posts/new-version-released--3
    ...
    etc.

Note that the number is preceded by "--" to distinguish it from the
rest of the slug. This is important to enable having slugs like:

    /cars/peugeot-206
    /cars/peugeot-206--2

You can configure the separator string used by your model by setting the
`:sequence_separator` option in {FriendlyId#has_friendly_id}:

    has_friendly_id :title, :use_slug => true, :sequence_separator => ";"

You can also override the default used in
{FriendlyId::Configuration::DEFAULTS} to set the value for any model using
FriendlyId. If you change this value in an existing application, be sure to
{file:Guide.md#regenerating_slugs regenerate the slugs} afterwards.

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

The strings "new" and "index" are reserved by default. When you attempt to
store a reserved value, FriendlyId raises a
{FriendlyId::ReservedError}. You can also override the default
reserved words in {FriendlyId::Configuration::DEFAULTS} to set the value for any
model using FriendlyId.

## Caching the FriendlyId Slug for Better Performance

Checking the slugs table all the time has an impact on performance, so as of
2.2.0, FriendlyId offers slug caching.

This feature can improve the performance of some views by about 25%, and
reduce memory consumption by about 40% as compared to the same view without
cached slugs. The biggest improvement will be for "index" type views with many
links that depend on slugs to generate the URL.

### Automatic setup

To enable slug caching, simply add a column named "cached_slug" to your model.
FriendlyId will automatically use this column if it detects it:

    class AddCachedSlugToUsers < ActiveRecord::Migration
      def self.up
        add_column :users, :cached_slug, :string
      end

      def self.down
        remove_column :users, :cached_slug
      end
    end

Then, redo the slugs:

    rake friendly_id:redo_slugs MODEL=User

This feature exists largely to improve the performance of URL generation, the
part of Rails where FriendlyId has the biggest performance impact. FriendlyId
never queries against this column, so it's not necessary to add an index on it
unless your application does.

Two warnings when using this feature:

*DO NOT* forget to redo the slugs, or else this feature will not work!

Also, this feature uses `attr_protected` to protect the `cached_slug` column,
unless you have already invoked `attr_accessible`. So if you wish to use
`attr_accessible`, you must invoke it BEFORE you invoke `has_friendly_id` in
your class.

### Using a custom column name

You can also use a different name for the column if you choose, via the
`:cache_column` config option:

    class User < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true, :cache_column => 'my_cached_slug'
    end


## Scoped Slugs

FriendlyId can generate unique slugs within a given scope. For example, assume
you have an application that displays restaurants. Without scoped slugs, if
two restaurants are named "Joe's Diner," the second one will end up with
"joes-diner--2" as its friendly_id. Using scoped allows you to keep the
slug names unique for each city, so that the second "Joe's Diner" could have
the slug "joes-diner" if it's located in a different city:

    class Restaurant < ActiveRecord::Base
      belongs_to :city
      has_friendly_id :name, :use_slug => true, :scope => :city
    end

    class City < ActiveRecord::Base
      has_many :restaurants
      has_friendly_id :name, :use_slug => true
    end

    http://example.org/cities/seattle/restaurants/joes-diner
    http://example.org/cities/chicago/restaurants/joes-diner

    Restaurant.find("joes-diner", :scope => "seattle")  # returns 1 record
    Restaurant.find("joes-diner", :scope => "chicago")  # returns 1 record
    Restaurant.find("joes-diner")                       # returns both records

The value for the `:scope` key in your model can be a custom method you
define, or the name of a relation. If it's the name of a relation, then the
scope's text value will be the result of calling `to_param` on the related
model record. In the example above, the city model also uses FriendlyId and so
its `to_param` method returns its friendly_id: "chicago" or "seattle".

### Updating a Relation's Scoped Slugs

When using a relation as the scope, updating the relation will update the
slugs, but only if both models have specified the relationship. In the above
example, updates to City will update the slugs for Restaurant because City
specifies that it `has_many :restaurants`.

### Routes for Scoped Models

Note that FriendlyId does not set up any routes for scoped models; you must
do this yourself in your application. Here's an example of one way to set
this up:

    # in routes.rb
    map.resources :restaurants
    map.restaurant "/restaurants/:scope/:id", :controller => "restaurants"

    # in views
    link_to 'Show', restaurant_path(restaurant.city, restaurant)

    # in controllers
    @restaurant = Restaurant.find(params[:id], :scope => params[:scope])


## FriendlyId Rake Tasks

FriendlyId provides several tasks to help maintain your application. The
tasks can be invoked via Rake, or programmatically through {FriendlyId::Tasks}.

### Generating New Slugs For the First Time

    friendly_id:make_slugs MODEL=<model name>

Use this task to generate slugs after installing FriendlyId in a new
application.

### Regenerating Slugs

    friendly_id:redo_slugs MODEL=<model name>

Use this task to regenerate slugs after making any changes to your model's
FriendlyId configuration options that affect slug generation. For example,
if you introduce a `cached_slug` column or change the `:seqence_separator`.

### Deleting Old Slugs

    rake friendly_id:remove_old_slugs MODEL=<model name> DAYS=<days>

Use this task if you wish to delete expired slugs; manually or perhaps via
cron. If you don't specify the days option, the default is to remove unused
slugs older than 45 days.

# Hacking FriendlyId

A couple of notes for programmers intending to work on FriendlyId:

If you intend to send a pull request, in general it's best to make minor
changes in the master branch, and major changes in the edge branch.

Before removing any public or protected methods, FriendlyId will deprecate
them through one major release cycle. Private methods may, however, change at
any time.