# FriendlyId

FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins for
Ruby on Rails. It allows you to create pretty URL's and work with
human-friendly strings as if they were numeric ids for ActiveRecord models.

Using FriendlyId, it's easy to make your application use URL's like:

    http://example.com/states/washington

instead of:

    http://example.com/states/4323454

## Docs, Info and Support

* [FriendlyId Guide](http://norman.github.com/friendly_id/file.Guide.html)
* [API Docs](http://norman.github.com/friendly_id)
* [Google Group](http://groups.google.com/group/friendly_id)
* [Source Code](http://github.com/norman/friendly_id/)
* [Issue Tracker](http://github.com/norman/friendly_id/issues)

## Rails Quickstart

    gem install friendly_id

    cd my_app

    ./script/generate friendly_id

    rake db:migrate

    class User < ActiveRecord::Base
      has_friendly_id :user_name, :use_slug => true
    end

    rake friendly_id:make_slugs

    ./script/server

    GET http://0.0.0.0:3000/users/joe-schmoe

## FriendlyId Features and Guide

FriendlyId offers many advanced features, including: slug history and
versioning, scoped slugs, reserved words, a custom slug generator, unicode and
accented characters. For more information on using FriendlyId, please see the
{file:GUIDE.md FriendlyId Guide}.

## Bugs:

Please report them on the [Github issue tracker](http://github.com/norman/friendly_id/issues)
for this project.

If you have a bug to report, please include the following information:

* Stack trace and error message.
* Version information for FriendlyId, Rails and Ruby.
* Any snippets of relevant model, view or controller code that shows how your are using FriendlyId.

If you are able to, it helps even more if you can fork FriendlyId on Github,
and add a test that reproduces the error you are experiencing.

## Credits:

FriendlyId was created by Norman Clarke, Adrian Mugnolo, and Emilio Tagua.

Copyright (c) 2008-2010, released under the MIT license.