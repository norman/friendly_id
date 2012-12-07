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
versioning, i18n, Globalize support, scoped slugs, reserved words, and custom
slug generators.

FriendlyId is compatible with Active Record **3.0** and higher.

## Version 4.x

FriendlyId 4.x introduces many changes incompatible with 3.x. If you're
upgrading, please [read the
docs](http://rubydoc.info/github/norman/friendly_id/master/file/WhatsNew.md) to see what's
new.

## Docs

The current docs can always be found
[here](http://rubydoc.info/github/norman/friendly_id/master/frames).

The best place to start is with the
[Guide](http://rubydoc.info/github/norman/friendly_id/master/file/Guide.rdoc),
which compiles the top-level RDocs into one outlined document.

You might also want to watch Ryan Bates's [Railscast on FriendlyId](http://railscasts.com/episodes/314-pretty-urls-with-friendlyid).

## Rails Quickstart

    gem install friendly_id

    rails new my_app

    cd my_app

    gem "friendly_id", "~> 4.0.1"

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
significant help early in its life by Emilio Tagua. I'm deeply grateful for the
generous contributions over the years from [many
volunteers](https://github.com/norman/friendly_id/contributors).

Part of the inspiration to rework FriendlyId came from Darcy Laycock's library
[Slugged](https://github.com/Sutto/slugged), which he was inspired to create
because of frustrations he experienced while using FriendlyId 3.x. Seeing a
smart programmer become frustrated with my code was enough of a kick in the
butt to make me want to significantly improve this library.

Many thanks to him for providing valid, real criticism while still being a cool
about it. I definitely recommend you check out his library if for some reason
FriendlyId doesn't do it for you.

Thanks also to Loren Segal and Nick Plante for YARD and the
[rubydoc.info](http://rubydoc.info/) website which FriendlyId uses for
documentation.

Lastly, FriendlyId uses [Travis](http://travis-ci.org/) for continuous
integration. It's an excellent, free service created by a whole bunch of [good
people](https://github.com/travis-ci) - if you're not already using it, you
should be!

## License

Copyright (c) 2008-2012 Norman Clarke and contributors, released under the MIT
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
