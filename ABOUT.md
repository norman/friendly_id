# FriendlyId 4

This is a rewrite/rethink of FriendlyId. It will probably be released some time
in August or September 2011, once I've had the chance to actually use it in a
real website for a while.

It's probably not wise to use this on a real site right now unless you're
comfortable with the source code and willing to fix bugs that will likely occur.

That said, I will soon be deploying this on a high-traffic, production site, so
I have a personal stake in making this work well. Your feedback is most welcome.

## Back to basics

This isn't the "big rewrite," it's the "small rewrite."

Adding new features with each release is not sustainable. This release *removes*
features, but makes it possible to add them back as addons. We can also remove
some complexity by relying on the better default functionality provided by newer
versions of Active Support and Active Record. Let's see how small we can make
this!

Here's what's changed:

## Active Record 3+ only

For 2.3 support, you can use FriendlyId 3, which will continue to be maintained
until people don't want it any more.

## In-table slugs

FriendlyId no longer creates a separate slugs table - it just stores the
generated slug value in the model table, which is simpler, faster and what most
people seem to want. Keeping slug history in a separate table is an optional
add-on for FriendlyId 4.

## No more multiple finds

    Person.find "joe-schmoe"               # Supported
    Person.find ["joe-schmoe", "john-doe"] # No longer supported

If you want find by more than one friendly id, build your own query:

    Person.where(:slug => ["joe-schmoe", "john-doe"])

This lets us do *far* less monkeypatching in Active Record. How much less?
FriendlyId overrides the base find with a mere 2 lines of code, and otherwise
changes nothing else. This means more stability and less breakage between Rails
updates.

## No more finder status

FriendlyId 3 offered finder statuses to help you determine when an outdated
or non-friendly id was used to find the record, so that you could decide whether
to permanently redirect to the canonical URL. However, there's a simpler way to
do that, so this feature has been removed:

    if request.path != person_path(@person)
      return redirect_to @person, :status => :moved_permanently
    end

## No more slug history - unless you want it

Since slugs are now stored in-table, when you update them, finds for the
previous slug will no longer work. This can be a problem for permalinks, since
renaming a friendly_id will lead to 404's.

This was transparently handled by FriendlyId 3, but there were three problems:

* Not everybody wants or needs this
* Performance was negatively affected
* Determining whether a current or old id was used was expensive, clunky, and
  inconsistent when finding inside relations.

Here's how to do this in FriendlyId 4:

    begin
      # First try a performant, transparent find by either numeric id, or
      # current friendly_id.
      @post = Post.find(params[:id])
    # That didn't work? Might be an out-of-date id.
    rescue ActiveRecord::NotFoundError
      # Explicit friendly_id-only find that considers slug history
      @post = Post.find_by_friendly_id(params[:id])
      # Now let's redirect to the current record
      if @post.friendly_id != params[:id]
        return redirect_to @post, :status => :moved_permanently
      end
    end

Under FriendlyId 4 this is a little more verbose, but offers much finer-grained
controler over the finding process, performs better, and has a much simpler
implementation.

## "Reserved words" are now just a normal validation

Rather than use a custom reserved words validator, use the validations provided
by Active Record. FriendlyId still reserves "new" and "edit" by default to avoid
routing problems.

    validates_exclusion_of :name, :in => ["bad", "word"]

You can configure the default words reserved by FriendlyId in
`FriendlyId::Configuration::DEFAULTS[:reserved_words]`.

## "Allow nil" is now just another validation

Previous versions of FriendlyId offered a special option to allow nil slug
values, but this is now the default. If you don't want this, then simply add a
validation to the slug column, and/or declare the column `NOT NULL` in your
database.

## Bye-bye Babosa

[Babosa](http://github.com/norman/babosa) is FriendlyId 3's slugging library.

FriendlyId 4 doesn't use it by default because the most important pieces of it
were already accepted into Active Support 3.

However, Babosa is still useful, for example, for idiomatically transliterating
Cyrillic ([or other
language](https://github.com/norman/babosa/tree/master/lib/babosa/transliterator))
strings to ASCII. It's very easy to include - just override
`#normalize_friendly_id` in your model:

    class MyModel < ActiveRecord::Base
      ...

      def normalize_friendly_id(text)
        text.to_slug.normalize! :transliterate => :russian
      end
    end

