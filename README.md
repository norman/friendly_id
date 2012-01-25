# FriendlyId

FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins for
Ruby on Rails. It allows you to create pretty URL's and work with
human-friendly strings as if they were numeric ids for Active Record models.

Using FriendlyId, it's easy to make your application use URL's like:

    http://example.com/states/washington

instead of:

    http://example.com/states/4323454

## FriendlyId Features

FriendlyId offers many advanced features, including: slug history and
versioning, scoped slugs, reserved words, custom slug generators, and
excellent Unicode support. For complete information on using FriendlyId,
please see the [FriendlyId Guide](https://github.com/norman/friendly_id/blob/3.x/Guide.md)

## Compatibility

FriendlyId 3.3.0 is compatible with Active Record 3.0, 3.1 and 3.2.

If you are still on Rails 2.3, please use FriendlyId 3.2.x.

## Roadmap

FriendlyId 3.3 is now in **long term maintenance mode.** It will continue to be
supported and maintained indefinitely, but no new features will be added to it.

[FriendlyId 4.0](https://github.com/norman/friendly_id/tree/4.0.0) is a
ground-up rewrite of FriendlyId, and is the project's future, and will be
released by September, 2011.

## Docs, Info and Support

* [FriendlyId Guide](https://github.com/norman/friendly_id/blob/3.x/Guide.md)
* [Source Code](http://github.com/norman/friendly_id/)
* [Issue Tracker](http://github.com/norman/friendly_id/issues)

## Rails Quickstart

    gem install friendly_id

    rails new my_app

    cd my_app

    # add to Gemfile
    gem "friendly_id", "~> 3.3.0"

    rails generate friendly_id
    rails generate scaffold user name:string cached_slug:string

    rake db:migrate

    # edit app/models/user.rb
    class User < ActiveRecord::Base
      has_friendly_id :name, :use_slug => true
    end

    User.create! :name => "Joe Schmoe"

    rails server

    GET http://0.0.0.0:3000/users/joe-schmoe

## Sequel and DataMapper, too

[Alex Coles](http://github.com/myabc) maintains an implemntation of
[FriendlyId for DataMapper](http://github.com/myabc/friendly_id_datamapper) that supports almost
all the features of the Active Record version.

Norman Clarke maintains an implementation of
[FriendlyId forSequel](http://github.com/norman/friendly_id_sequel) with some of the features
of the Active Record version.

## Bugs

Please report them on the [Github issue tracker](http://github.com/norman/friendly_id/issues)
for this project.

If you have a bug to report, please include the following information:

* **Version information for FriendlyId, Rails and Ruby.**
* Stack trace and error message.
* Any snippets of relevant model, view or controller code that shows how your
  are using FriendlyId.

If you are able to, it helps even more if you can fork FriendlyId on Github,
and add a test that reproduces the error you are experiencing.

## Credits

FriendlyId was created by Norman Clarke, Adrian Mugnolo, and Emilio Tagua.

If you like FriendlyId, please recommend us on Working With Rails:

* [http://bit.ly/recommend-norman](http://bit.ly/recommend-norman)
* [http://bit.ly/recommend-emilio](http://bit.ly/recommend-emilio)
* [http://bit.ly/recommend-adrian](http://bit.ly/recommend-adrian)

Thanks!

Copyright (c) 2008-2010, released under the MIT license.
