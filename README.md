# FriendlyId

[![Build Status](https://travis-ci.org/norman/friendly_id.png)](https://travis-ci.org/norman/friendly_id)

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

FriendlyId is compatible with Active Record **3.2** and higher.

## Version 5.x

As of version 5.0, FriendlyId uses semantic versioning. Therefore, as you might
infer from the version number, FriendlyId 5.0 introduces changes incompatible
with 4.x. If you're upgrading, please [read the
docs](http://rubydoc.info/github/norman/friendly_id/master/file/WhatsNew.md) to
see what's new.

Here's a summary of the most important changes:

* FriendlyId no longer overrides `find`. If you want to do friendly finds, you
  must do `Model.friendly.find` rather than `Model.find`.

* Version 5.0 offers a new "candidates" functionality which makes it easy to
  set up a list of alternate slugs that can be used to uniquely distinguish
  records, rather than appending a sequence.

* Now that candidates have been added, FriendlyId no longer uses a numeric
  sequence to differentiate conflicting slug, but rather a GUID. This makes the
  codebase simpler and more reliable when running concurrently, at the expense
  of uglier ids being generated when there are conflicts.

* FriendlyId now requires Ruby 1.9.3 or higher.

## Docs

The current docs can always be found
[here](http://rubydoc.info/github/norman/friendly_id/master/frames).

The best place to start is with the
[Guide](http://rubydoc.info/github/norman/friendly_id/master/file/Guide.rdoc),
which compiles the top-level RDocs into one outlined document.

You might also want to watch Ryan Bates's [Railscast on FriendlyId](http://railscasts.com/episodes/314-pretty-urls-with-friendlyid),
which is now somewhat outdated but still mostly relevant.

## Rails Quickstart

    gem install friendly_id

    rails new my_app

    cd my_app

    gem "friendly_id", "~> 5.0.0" # Note: You MUST use 5.0.0 or greater for Rails 4.0+

    rails generate scaffold user name:string slug:string

    # edit db/migrate/*_create_users.rb
    add_index :users, :slug, unique: true

    rake db:migrate

    # edit app/models/user.rb
    class User < ActiveRecord::Base
      extend FriendlyId
      friendly_id :name, use: :slugged
    end

    User.create! name: "Joe Schmoe"

    # Change User.find to User.friendly.find in your controller
    User.friendly.find(params[:id])

    rails server

    GET http://localhost:3000/users/joe-schmoe

    # If you're adding FriendlyId to an existing app and need
    # to generate slugs for existing users, do this from the
    # console, runner, or add a Rake task:
    User.find_each(&:save)


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
