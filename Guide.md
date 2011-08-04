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

### Using a Custom Method to Generate the Slug Text

FriendlyId can use either a column or a method to generate the slug text for
your model:

    class City < ActiveRecord::Base
      extend FriendlyId
      belongs_to :country
      friendly_id :name_and_country, :use => :slugged

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
      extend FriendlyId
      friendly_id :whatever, :use => :slugged

      def normalize_friendly_id(text)
        my_text_modifier_method(text)
      end

    end

The `normalize_friendly_id` method takes a single argument and receives an
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
`:sequence_separator` option in `friendly_id`:

    friendly_id :title, :use => :slugged, :sequence_separator => ":"

You can also override the default used in
{FriendlyId::Configuration::DEFAULTS} to set the value for any model using
FriendlyId. If you change this value in an existing application, be sure to
{file:Guide.md#regenerating_slugs regenerate the slugs} afterwards.

For reasons I hope are obvious, you can't change this value to "-". If you try,
FriendlyId will raise an error.

## Reserved Words

When you use slugs, FriendlyId adds a validation to avoid using "new" and
"index" as slugs. You can control the default reserved words by changing the
value in `FriendlyId::Configuration::DEFAULTS[:reserved_words]`.

## Scoped Slugs


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

    activerecord (3.0.9)
    ruby 1.9.2p180 (2011-02-18 revision 30909) [x86_64-darwin10.6.0]
    friendly_id (4.0.0.beta1)
    sqlite3 (1.3.3) gem
    sqlite3 3.6.12 in-memory database


                                      user     system      total        real
    find (without FriendlyId)     0.300000   0.000000   0.300000 (  0.306729)
    find (in-table slug)          0.350000   0.000000   0.350000 (  0.351760)
    find (external slug)          3.320000   0.000000   3.320000 (  3.326749)
    insert (without FriendlyId)   0.810000   0.010000   0.820000 (  0.810513)
    insert (in-table-slug)        1.740000   0.000000   1.740000 (  1.743511)
    insert (external slug)        3.540000   0.010000   3.550000 (  3.544898)
