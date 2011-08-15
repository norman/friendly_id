# FriendlyId

[![Build Status](http://travis-ci.org/norman/friendly_id.png)](http://travis-ci.org/norman/friendly_id)

FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins for
Ruby on Rails. It allows you to create pretty URL's and work with human-friendly
strings as if they were numeric ids for Active Record models.

Using FriendlyId, it's easy to make your application use URL's like:

    http://example.com/states/washington

instead of:

    http://example.com/states/4323454


## FriendlyId Features

FriendlyId offers many advanced features, including: slug history and
versioning, scoped slugs, reserved words, and custom slug generators.

FriendlyId is compatible with Active Record **3.0** and **3.1**.

## Version 4.x

FriendlyId 4.x introduces many changes incompatible with 3.x. If you're upgrading,
please read the docs to see what's new.

## Rails Quickstart

    gem install friendly_id

    rails new my_app

    cd my_app

    # Add to Gemfile - this will change once version 4 is no longer
    # in beta, but for now do this:
    gem "friendly_id4", "4.0.0.beta4", :require => "friendly_id"


    rails generate scaffold user name:string slug:string

    # edit db/migrate/*_create_users.rb
    add_index :users, :slug, :unique => true

    rake db:migrate

    # edit app/models/user.rb
    class User < ActiveRecord::Base
      extend FriendlyId
      friendly_id :name, :use => :slugged
    end

    User.create! :name => "Joe Schmoe"

    rails server

    GET http://localhost:3000/users/joe-schmoe

## Docs

The current docs can be found
[here](http://rdoc.info/github/norman/friendly_id/a4128af31d85ee29ad8f/frames).

## Benchmarks

The latest benchmarks for FriendlyId are maintained
[here](https://gist.github.com/1129745).


## Bugs

Please report them on the [Github issue
tracker](http://github.com/norman/friendly_id/issues) for this project.

If you have a bug to report, please include the following information:

* **Version information for FriendlyId, Rails and Ruby.**
* Stack trace and error message.
 * Any snippets of relevant model, view or controller code that shows how you
  are using FriendlyId.

If you are able to, it helps even more if you can fork FriendlyId on Github,
and add a test that reproduces the error you are experiencing.

## Credits

FriendlyId was originally created by Norman Clarke and Adrian Mugnolo, with
significant help early in its life by Emilio Tagua. I'm deeply gratful for the
generous contributions over the years from [many
volunteers](https://github.com/norman/friendly_id/contributors).

Lastly, FriendlyId uses [Travis](http://travis-ci.org/) for continuous
integration. It's an excellent, free service created by a whole bunch of [good
people](https://github.com/travis-ci) - if you're not already using it, you
should be!

Copyright (c) 2008-2011 Norman Clarke, released under the MIT license.
