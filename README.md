[![Build Status](https://travis-ci.org/norman/friendly_id.svg)](https://travis-ci.org/norman/friendly_id)
[![Code Climate](https://codeclimate.com/github/norman/friendly_id.svg)](https://codeclimate.com/github/norman/friendly_id)
[![Inline docs](http://inch-ci.org/github/norman/friendly_id.svg?branch=master)](http://inch-ci.org/github/norman/friendly_id)

**GETTING HELP**

Please ask questions on [Stack
Overflow](http://stackoverflow.com/questions/tagged/friendly-id) using the
"friendly-id" tag. Prior to asking, search and see if your question has
already been answered.

Please only post issues in Github issues for actual bugs.

I am asking people to do this because the same questions keep getting asked
over and over and over again in the issues.

# FriendlyId

**For the most complete, user-friendly documentation, see the [FriendlyId Guide](http://norman.github.io/friendly_id/file.Guide.html).**

FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins for
Active Record. It lets you create pretty URLs and work with human-friendly
strings as if they were numeric ids.

With FriendlyId, it's easy to make your application use URLs like:

    http://example.com/states/washington

instead of:

    http://example.com/states/4323454


## FriendlyId Features

FriendlyId offers many advanced features, including: slug history and
versioning, i18n, scoped slugs, reserved words, and custom slug generators.

### What Changed in Version 5.1

5.1 is a bugfix release, but bumps the minor version because some applications may be dependent
on the previously buggy behavior. The changes include:

* Blank strings can no longer be used as slugs.
* When the first slug candidate is rejected because it is reserved, additional candidates will
  now be considered before marking the record as invalid.
* The `:finders` module is now compatible with Rails 4.2.

### What Changed in Version 5.0

As of version 5.0, FriendlyId uses [semantic versioning](http://semver.org/). Therefore, as you might
infer from the version number, 5.0 introduces changes incompatible with 4.0.

The most important changes are:

* Finders are no longer overridden by default. If you want to do friendly finds,
  you must do `Model.friendly.find` rather than `Model.find`. You can however
  restore FriendlyId 4-style finders by using the `:finders` addon:

  ```ruby
  friendly_id :foo, use: :slugged # you must do MyClass.friendly.find('bar')
  # or...
  friendly_id :foo, use: [:slugged, :finders] # you can now do MyClass.find('bar')
  ```
* A new "candidates" functionality which makes it easy to set up a list of
  alternate slugs that can be used to uniquely distinguish records, rather than
  appending a sequence. For example:

  ```ruby
  class Restaurant < ActiveRecord::Base
    extend FriendlyId
    friendly_id :slug_candidates, use: :slugged

    # Try building a slug based on the following fields in
    # increasing order of specificity.
    def slug_candidates
      [
        :name,
        [:name, :city],
        [:name, :street, :city],
        [:name, :street_number, :street, :city]
      ]
    end
  end
  ```
* Now that candidates have been added, FriendlyId no longer uses a numeric
  sequence to differentiate conflicting slug, but rather a UUID (e.g. something
  like `2bc08962-b3dd-4f29-b2e6-244710c86106`). This makes the
  codebase simpler and more reliable when running concurrently, at the expense
  of uglier ids being generated when there are conflicts.
* The default sequence separator has been changed from two dashes to one dash.
* Slugs are no longer regenerated when a record is saved. If you want to regenerate
  a slug, you must explicitly set the slug column to nil:

  ```ruby
  restaurant.friendly_id # joes-diner
  restaurant.name = "The Plaza Diner"
  restaurant.save!
  restaurant.friendly_id # joes-diner
  restaurant.slug = nil
  restaurant.save!
  restaurant.friendly_id # the-plaza-diner
  ```

  You can restore some of the old behavior by overriding the
  `should_generate_new_friendly_id?` method.
* The `friendly_id` Rails generator now generates an initializer showing you
  how to do some common global configuration.
* The Globalize plugin has moved to a [separate gem](https://github.com/norman/friendly_id-globalize) (currently in alpha).
* The `:reserved` module no longer includes any default reserved words.
  Previously it blocked "edit" and "new" everywhere. The default word list has
  been moved to `config/initializers/friendly_id.rb` and now includes many more
  words.
* The `:history` and `:scoped` addons can now be used together.
* Since it now requires Rails 4, FriendlyId also now requires Ruby 1.9.3 or
  higher.

#### Upgrading from FriendlyId 4.0

Run `rails generate friendly_id --skip-migration` and edit the initializer
generated in `config/initializers/friendly_id.rb`. This file contains notes
describing how to restore (or not) some of the defaults from FriendlyId 4.0.

If you want to use the `:history` and `:scoped` addons together, you must add a
`:scope` column to your friendly_id_slugs table and replace the unique index on
`:slug` and `:sluggable_type` with a unique index on those two columns, plus
the new `:scope` column.

A migration like this should be sufficient:

```ruby
add_column   :friendly_id_slugs, :scope, :string
remove_index :friendly_id_slugs, [:slug, :sluggable_type]
add_index    :friendly_id_slugs, [:slug, :sluggable_type]
add_index    :friendly_id_slugs, [:slug, :sluggable_type, :scope], unique: true
```

## Articles

[Migrating an ad-hoc URL slug system to FriendlyId](http://olivierlacan.com/posts/migrating-an-ad-hoc-url-slug-system-to-friendly-id/)  
[Pretty URLs with FriendlyId](http://railscasts.com/episodes/314-pretty-urls-with-friendlyid)

## Docs

The most current docs from the master branch can always be found
[here](http://norman.github.io/friendly_id).

Docs for older versions are also available:

* [5.0](http://norman.github.io/friendly_id/5.0/)
* [4.0](http://norman.github.io/friendly_id/4.0/)
* [3.3](http://norman.github.io/friendly_id/3.3/)
* [2.3](http://norman.github.io/friendly_id/2.3/)

The best place to start is with the
[Guide](http://norman.github.io/friendly_id/file.Guide.html),
which compiles the top-level RDocs into one outlined document.

For a getting started video, you may want to watch [GoRails #9](https://gorails.com/episodes/pretty-urls-with-friendly-id)

You might also want to watch Ryan Bates's [Railscast on FriendlyId](http://railscasts.com/episodes/314-pretty-urls-with-friendlyid),
which is now somewhat outdated but still relevant.


## Rails Quickstart

```shell
rails new my_app
cd my_app
```
```ruby
# Gemfile
gem 'friendly_id', '~> 5.1.0' # Note: You MUST use 5.0.0 or greater for Rails 4.0+
```
```shell
rails generate friendly_id
rails generate scaffold user name:string slug:string:uniq
rake db:migrate
```
```ruby
# edit app/models/user.rb
class User < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
end

User.create! name: "Joe Schmoe"

# Change User.find to User.friendly.find in your controller
User.friendly.find(params[:id])
```
```shell
rails server

GET http://localhost:3000/users/joe-schmoe
```
```ruby
# If you're adding FriendlyId to an existing app and need
# to generate slugs for existing users, do this from the
# console, runner, or add a Rake task:
User.find_each(&:save)
```

## Benchmarks

The latest benchmarks for FriendlyId are maintained
[here](http://bit.ly/friendly-id-benchmarks).


## Bugs

Please report them on the [Github issue
tracker](http://github.com/norman/friendly_id/issues) for this project.

If you have a bug to report, please include the following information:

* **Version information for FriendlyId, Rails and Ruby.**
* Full stack trace and error message (if you have them).
* Any snippets of relevant model, view or controller code that shows how you
  are using FriendlyId.

If you are able to, it helps even more if you can fork FriendlyId on Github,
and add a test that reproduces the error you are experiencing.

For more info on how to report bugs, please see [this
article](http://yourbugreportneedsmore.info/).

## Thanks and Credits

FriendlyId was originally created by Norman Clarke and Adrian Mugnolo, with
significant help early in its life by Emilio Tagua. It is now maintained by
Norman Clarke and Philip Arndt.

We're deeply grateful for the generous contributions over the years from [many
volunteers](https://github.com/norman/friendly_id/contributors).

## License

Copyright (c) 2008-2016 Norman Clarke and contributors, released under the MIT
license.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
