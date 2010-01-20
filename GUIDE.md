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
These features are explained in detail below.

## Installation

FriendlyId can be installed as a gem, or as a Rails plugin. It is compatible
with Rails 2.2.x, 2.3.x, and 3.x (mostly).

### As a Gem

    gem install friendly_id

#### Rails 2.2.x - 2.3.x

After installing the gem, you will need to add an entry in environment.rb:

    config.gem "friendly_id"

#### Rails 3.x

Add an entry in the `Gemfile` for `friendly_id`, and in  `config/environment.rb`, add:

    Bundler.require_env

somewhere before `Application.initialize!`.

### As a Plugin

Plugin installtion is simple for all supported versions of Rails:

    ./script/plugin install git://github.com/norman/friendly_id.git

However, installing as a gem offers simpler version control than plugin
installtion. Whenever possible, install as a gem instead.

### Setup

After installing either as a gem or plugin, run:

    ./script/generate friendly_id
    rake db:migrate

This will install the Rake tasks and slug migration for FriendlyId. If you are
not going to use slugs, you can do:

    ./script/generate friendly_id --skip-migration

*Note: The generator does not currently work with Rails 3. This will be fixed soon.*

FriendlyId is now set up and ready for you to use.

## Configuration

FriendlyId is configured using the {FriendlyId#has_friendly_id} class method:

    class MyModel < ActiveRecord::Base
      has_friendly_id :a_column_or_method options_hash
    end

For a list of valid options, see the instance attrbute summary for {FriendlyId::Config}.

# Features

## FriendlyId Strings

When using slugs, FriendlyId will automatically modify the slug text to make
it more suitable for use in a URL:

    class City < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true
    end

    @city.create :name => "Viña del Mar"
    @city.friendly_id  # will be "viña-del-mar"

By default, the string is {SlugString#downcase! downcased} and {SlugString#clean! stripped}, {SlugString#with_dashes! spaces are replaced with dashes},
and {SlugString#letters! non-letters are removed}.

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

## Using a Custom Method to Process the Slug Text

If the built-in slug text handling options don't work for your application,
you can override the `normalize_friendly_id` method in your model class in
order to fine-tune the output:

    class City < ActiveRecord::Base

      def normalize_friendly_id(text)
        text.clean.approximate_ascii.underscore.upcase
      end

    end

The normalize_friendly_id method takes a single argument and receives an
instance of {FriendlyId::SlugString}, a class which wraps a regular Ruby
string with some additional formatting options inherits Multibyte support from
ActiveSupport::Multibyte::Chars.

### Converting non-Western characters to ASCII with Stringex
## Redirecting to the Current Friendly URL
## Non-unique Slugs
## Reserved Words
## Caching the FriendlyId Slug for Better Performance
## Scoped Slugs
## FriendlyId Rake Tasks
### Generating New Slugs
### Deleting Old Slugs