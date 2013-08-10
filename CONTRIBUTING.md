# FriendlyId

## Getting Help

Before opening a new issue, please search the existing issues to see if your
question has been answered before.

Please also take a look at the extensive documentation, especially the Guide.

## FAQ

Here are the answers to some common questions.

### I'm using Rails 4...

Then you **must** use FriendlyId 5, which is currently available in the master
branch of the repository, and will be released to Rubygems soon.

### How do I set up my routes for FriendlyId?

Exactly like in any other Rails app. FriendlyId doesn't change any routing
functionality, it only changes the ids that are shown in your routes.

TIP: Make your app work the way you want to with numeric id's. Then add
FriendlyId later.

### I'm seeing `undefined method `friendly_id'`

You probably just added the friendly_id gem. Run `bundle` and restart your
Rails app.

### I'm seeing `uninitialized constant FriendlyId`

You probably just added the friendly_id gem. Run `bundle` and restart your
Rails app.

