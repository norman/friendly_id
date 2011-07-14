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
non-Rails applications, and with [Sequel](http://github.com/norman/friendly_id_sequel) and
[DataMapper](http://github.com/myabc/friendly_id_datamapper).

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
because FriendlyId provides many useful features that only work with this
feature. These features are explained in detail {file:Guide.md#features below}.

## Installation

### Gem installation

    gem install friendly_id

After installing the gem, add an entry in the Gemfile:

    gem "friendly_id", "~> 3.3.0"

### Roadmap

FriendlyId 3.3 is now in **long term maintenance mode.** It will continue to be
supported and maintained indefinitely, but no new features will be added to it.

[FriendlyId 4.0](https://github.com/norman/friendly_id/tree/4.0.0) is a
ground-up rewrite of FriendlyId, and is the project's future, and will be
released by September, 2011.

### Setup

    rails generate friendly_id
    rake db:migrate

This will install the Rake tasks and slug migration for FriendlyId. If you are
not going to use slugs, you can use the `skip-migration` option:

    rails generate friendly_id --skip-migration

FriendlyId is now set up and ready for you to use.

## Configuration

FriendlyId is configured in your model using the `has_friendly_id` method:

    has_friendly_id :a_column_or_method options_hash

    class Post < ActiveRecord::Base
      # use the "title" column as the basis of the friendly_id, and use slugs
      has_friendly_id :title, :use_slug => true,
        # remove accents and other diacritics from Latin characters
        :approximate_ascii => true,
        # don't use slugs larger than 50 bytes
        :max_length => 50
    end

Read on to learn about the various features that can be configured. For the
full list of valid configuration options, see the instance attribute summary
for {FriendlyId::Configuration}.

# Features

## FriendlyId Strings

FriendlyId uses the [Babosa](http://github.com/norman/babosa) library for
generating slug strings. When using slugs, FriendlyId/Babosa will automatically
modify the slug text to make it more suitable for use in a URL:

    class City < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true
    end

    @city.create :name => "Viña del Mar"
    @city.friendly_id  # will be "viña-del-mar"

By default, the string is downcased and stripped, spaces are replaced with
dashes, and non-word characters other than "-" are removed.

### Replacing Accented Characters

If your strings use Latin characters, you can use the `:approximate_ascii` option to remove
accents and other diacritics:

    class City < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true, :approximate_ascii => true
    end

    @city.create :name => "Łódź, Poland"
    @city.friendly_id  # will be "lodz-poland"

There are special options for some languages:

    class Person < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true, :approximate_ascii => true,
        :ascii_approximation_options => :german
    end

    @person.create :name => "Jürgen Müller"
    @person.friendly_id  # will be "juergen-mueller"

FriendlyId supports whatever languages are supported by
[Babosa](https://github.com/norman/babosa); at the time of writing, this
includes Danish, German, Serbian and Spanish.

### Unicode Slugs

By default, any character outside the Unicode Latin character range will be
passed through untouched, allowing you to have slugs in Arabic, Japanese,
Greek, etc:

    @post.create :title => "katakana: ゲコゴサザシジ!"
    @post.friendly_id # will be: "katakana-ゲコゴサザシジ"

### ASCII Slugs

You can also configure FriendlyId using `:strip_non_ascii` to simply delete
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
instance of {FriendlyId::SlugString}, a class which wraps a regular Ruby string
with additional formatting options.

### Converting non-Latin characters to ASCII with Stringex

Stringex is a library which provides some interesting options for transliterating
non-Latin strings to ASCII:

    "你好".to_url => "ni-hao"

Using Stringex with FriendlyId is a simple matter of installing and requiring
the `stringex` gem, and overriding the `normalize_friendly_id` method in your
model:

    class City < ActiveRecord::Base
      def normalize_friendly_id(text)
        text.to_url
      end
    end

However, be aware of some limitations of Stringex - it just does a context-free
character-by-character approximation for Unicode strings without sensitivity to
the string's language. This means, for example, that the Han characters used by
Japanese, Mandarin, Cantonese, and other languages are all replaced with the
same ASCII text. For Han characters, Stringex uses Mandarin, which makes its
output on Japanese text useless. You can read more about the limitations of
Stringex in [the documentation for
Unidecoder](http://search.cpan.org/~sburke/Text-Unidecode-0.04/lib/Text/Unidecode.pm#DESIGN_GOALS_AND_CONSTRAINTS),
the Perl library upon which Stringex is based.

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

## Caching the FriendlyId Slug for Better Performance

Checking the slugs table all the time has an impact on performance, so as of
2.2.0, FriendlyId offers slug caching.

### Automatic setup

To enable slug caching, simply add a column named "cached_slug" to your model.
FriendlyId will automatically use this column if it detects it:

    class AddCachedSlugToUsers < ActiveRecord::Migration
      def self.up
        add_column :users, :cached_slug, :string
        add_index  :users, :cached_slug, :unique => true
      end

      def self.down
        remove_column :users, :cached_slug
      end
    end

Then, redo the slugs:

    rake friendly_id:redo_slugs MODEL=User

FriendlyId will automatically query against the cache column if it's available,
which will <a href="#some_benchmarks">improve the performance</a> of many queries.

A few warnings when using this feature:

* *DO NOT* forget to redo the slugs, or else this feature will not work!
* This feature uses `attr_protected` to protect the `cached_slug` column,
  unless you have already invoked `attr_accessible`. If you wish to use
  `attr_accessible`, you must invoke it BEFORE you invoke `has_friendly_id` in
  your class.
* Cached slugs [are incompatible with scopes](#scoped_models_and_cached_slugs) and
  are ignored if your model uses the `:scope option`.

### Using a custom column name

You can also use a different name for the column if you choose, via the
`:cache_column` config option:

    class User < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true, :cache_column => 'my_cached_slug'
    end

Don't use "slug" or "slugs" because FriendlyId needs those names for its own
purposes.

## Nil slugs and skipping validations

You can choose to allow `nil` friendly_ids via the `:allow_nil` config option:

    class User < ActiveRecord::Base
      has_friendly_id :name, :allow_nil => true
    end

This works whether the model uses slugs or not.

For slugged models, if the friendly_id text is `nil`, no slug will be created.
This can be useful, for example, to only create slugs for published articles
and avoid creating many slugs with sequences.

For models that don't use slugs, this will make FriendlyId skip all its
validations when the friendly_id text is `nil`. This can be useful, for
example, if you wish to add the friendly_id value in an `:after_save` callback.

For non-slugged models, if you simply wish to skip friendly_ids's validations
for some reason, you can override the `skip_friendly_id_validations` method.
Note that this method is **not** used by slugged models.

## Scoped Slugs

_Note that in FriendlyId prior to 3.2.0, you could specify a non-standard
`:scope` argument on finds. This feature has been removed in 3.2.0 in favor of
the query stategies described below._

FriendlyId can generate unique slugs within a given scope. For example, assume
you have an application that displays restaurants. Without scoped slugs, if two
restaurants are named "Joe's Diner," the second one will end up with
"joes-diner--2" as its friendly_id. Using scoped allows you to keep the slug
names unique for each city, so that the second "Joe's Diner" can also have the
slug "joes-diner", as long as it's located in a different city:

    class Restaurant < ActiveRecord::Base
      belongs_to :city
      has_friendly_id :name, :use_slug => true, :scope => :city
    end

    class City < ActiveRecord::Base
      has_many :restaurants
      has_friendly_id :name, :use_slug => true
    end

    City.find("seattle").restaurants.find("joes-diner")
    City.find("chicago").restaurants.find("joes-diner")


The value for the `:scope` key in your model can be a custom method you
define, or the name of a relation. If it's the name of a relation, then the
scope's text value will be the result of calling `to_param` on the related
model record. In the example above, the city model also uses FriendlyId and so
its `to_param` method returns its friendly_id: "chicago" or "seattle".

### Complications with Scoped Slugs

#### Scoped Models and Cached Slugs

If you want to use cached slugs with scoped models, be sure not to create a unique index on the
`cached_slug` column.


#### Finding Records by friendly\_id

If you are using scopes your friendly ids may not be unique, so a simple find like

    Restaurant.find("joes-diner")

may return the wrong record. In these cases when you want to use the friendly\_id for queries,
either query as a relation, or specify the scope in your query conditions:

    # will only return restaurants named "Joe's Diner" in the given city
    @city.restaurants.find("joes-diner")

    # or

    Restaurants.find("joes-diner", :include => :slugs, :conditions => {:slugs => {:scope => @city.to_param}})


#### Finding All Records That Match a Scoped ID

If you want to find all records with a particular friendly\_id regardless of scope,
the easiest way is to use cached slugs and query this column directly:

    Restaurant.find_all_by_cached_slug("joes-diner")


If you're not using cached slugs, then this is slightly more complicated, but
still doable:

    name, sequence = params[:id].parse_friendly_id
    Restaurant.all(:include => :slugs, :conditions => {
      :slugs => {:name => name, :sequence => sequence}
    })


#### Updating a Relation's Scoped Slugs

When using a relation as the scope, updating the relation will update the slugs,
but only if both models have specified the relationship. In the above example,
updates to City will update the slugs for Restaurant because City specifies that
it `has_many :restaurants`.

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


## FriendlyId Rake Tasks

FriendlyId provides several tasks to help maintain your application.

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

## MySQL MyISAM tables

Currently, the default FriendlyId migration will not work with MyISAM tables
because it creates an index that's too large. The easiest way to work around
this is to change the generated migration to add limits on some column lengths.
Please see [this issue](http://github.com/norman/friendly_id/issues#issue/50) in
the FriendlyId issue tracker for more information.

# Hacking FriendlyId

A couple of notes for programmers intending to work on FriendlyId:

If you intend to send a pull request, in general it's best to make minor
changes in the master branch, and major changes in the edge branch.

Before removing any public or protected methods, FriendlyId will deprecate
them through one major release cycle. Private methods may, however, change at
any time.

## Some Benchmarks

These benchmarks can give you an idea of FriendlyId's impact on the
performance of your application. Of course your results may vary.

Note that much of the performance difference can be attributed to finding an
SQL record by a text column. Finding a single record by numeric primary key is
always the fastest operation, and thus the best choice when possible. If you
decide not to use FriendlyId for performance reasons, keep in mind that your
own solution is unlikely to be any faster than FriendlyId with cached slugs
enabled. But if it is, then your patches would be very welcome!


    activerecord (3.0.0)
    ruby 1.9.2p0 (2010-08-18 revision 29036) [x86_64-darwin10.4.0]
    friendly_id (3.1.4)
    sqlite3-ruby (1.3.1)
    sqlite3 3.6.12 in-memory database

                                                       | DEFAULT | NO_SLUG |    SLUG | CACHED_SLUG |
    ------------------------------------------------------------------------------------------------
    find model by id                             x1000 |   0.286 |   0.365 |   0.518 |       0.393 |
    find model using array of ids                x1000 |   0.329 |   0.441 |   0.709 |       0.475 |
    find model using id, then to_param           x1000 |   0.321 |   0.332 |   0.976 |       0.399 |
    ================================================================================================
    Total                                              |   0.936 |   1.138 |   2.203 |       1.266 |

