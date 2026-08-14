# @guide begin
#
# ## About FriendlyId
#
# FriendlyId is an add-on to Ruby's Active Record that allows you to replace ids
# in your URLs with strings:
#
#     # without FriendlyId
#     http://example.com/states/4323454
#
#     # with FriendlyId
#     http://example.com/states/washington
#
# It requires few changes to your application code and offers flexibility,
# performance and a well-documented codebase.
#
# ### Core Concepts
#
# #### Slugs
#
# The concept of *slugs* is at the heart of FriendlyId.
#
# A slug is the part of a URL which identifies a page using human-readable
# keywords, rather than an opaque identifier such as a numeric id. This can make
# your application more friendly both for users and search engines.
#
# #### Finders: Slugs Act Like Numeric IDs
#
# To the extent possible, FriendlyId lets you treat text-based identifiers like
# normal IDs. This means that you can perform finds with slugs just like you do
# with numeric ids:
#
#     Person.find(82542335)
#     Person.friendly.find("joe")
#
# @guide end

require "friendly_id/core"

# FriendlyId ships one adapter per persistence library:
#
#     require "friendly_id/active_record"   # Rails / Active Record
#     require "friendly_id/rom"             # ROM (also aliased as friendly_id/hanami)
#
# Requiring "friendly_id" on its own loads the Active Record adapter when Active
# Record is available, so that existing Rails applications need no changes. If
# Active Record is not present, only the ORM-agnostic core is loaded and you are
# expected to require an adapter yourself.
begin
  require "active_record"
rescue LoadError
  # No Active Record. Core is loaded; the caller chooses an adapter.
else
  require "friendly_id/active_record"
end
