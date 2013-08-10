# FriendlyId

**VERSION NOTE**

**Rails 4**:
Master branch of this repository contains FriendlyId 5 which is compatible with Rails 4.
This version is under active development and not yet fully stable.

**Rails 3**:
If you wish to use this gem with Rails 3.1 or 3.2 you need to use FriendlyId version 4, which is the current stable release.
Please see [4.0-stable
branch](https://github.com/FriendlyId/friendly_id/tree/4.0-stable).

[![Build Status](https://travis-ci.org/FriendlyId/friendly_id.png)](https://travis-ci.org/FriendlyId/friendly_id)

FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins for
Ruby on Rails. It allows you to create pretty URLs and work with human-friendly
strings as if they were numeric ids for Active Record models.

Using FriendlyId, it's easy to make your application use URLs like:

    http://example.com/states/washington

instead of:

    http://example.com/states/4323454


## FriendlyId Features

FriendlyId offers many advanced features, including: slug history and
versioning, i18n, scoped slugs, reserved words, and custom slug generators.

Note: FriendlyId 5.0 is compatible with Active Record **4.0** and higher only.
For Rails 3.x, please use FriendlyId 4.x.


## Version 5.x

As of version 5.0, FriendlyId uses semantic versioning. Therefore, as you might
infer from the version number, FriendlyId 5.0 introduces changes incompatible
with 4.x.

Here's a summary of the most important changes:

* FriendlyId no longer overrides `find`. If you want to do friendly finds, you
  must do `Model.friendly.find` rather than `Model.find`.

* Version 5.0 offers a new "candidates" functionality which makes it easy to
  set up a list of alternate slugs that can be used to uniquely distinguish
  records, rather than appending a sequence. For example:

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
  sequence to differentiate conflicting slug, but rather a GUID. This makes the
  codebase simpler and more reliable when running concurrently, at the expense
  of uglier ids being generated when there are conflicts.

* The Globalize module has been removed and will be released as its own gem.
  Note that it has not yet been developed.

* The default sequence separator is now `-` rather than `--`.

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

* Like Rails 4, FriendlyId now requires Ruby 1.9.3 or higher.

## Docs

The current docs can always be found
[here](http://rubydoc.info/github/FriendlyId/friendly_id/master/frames).

The best place to start is with the
[Guide](http://rubydoc.info/github/FriendlyId/friendly_id/master/file/Guide.md),
which compiles the top-level RDocs into one outlined document.

You might also want to watch Ryan Bates's [Railscast on FriendlyId](http://railscasts.com/episodes/314-pretty-urls-with-friendlyid),
which is now somewhat outdated but still mostly relevant.

## Rails Quickstart

```shell
rails new my_app
cd my_app
```
```ruby
# Gemfile
gem 'friendly_id', github: 'FriendlyId/friendly_id', branch: 'master' # Note: You MUST use 5.0.0 or greater for Rails 4.0+
```
```shell
rails generate scaffold user name:string slug:string
```
```ruby
# edit db/migrate/*_create_users.rb
add_index :users, :slug, unique: true
```
```shell
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
tracker](http://github.com/FriendlyId/friendly_id/issues) for this project.

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
volunteers](https://github.com/FriendlyId/friendly_id/contributors).

## License

Copyright (c) 2008-2013 Norman Clarke and contributors, released under the MIT
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
