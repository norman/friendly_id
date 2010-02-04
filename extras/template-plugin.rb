run "rm public/index.html"
inside 'vendor/plugins' do
  run "git clone ../../../ friendly_id"
end
gem "haml"
gem "will_paginate"
run "haml --rails ."
generate "friendly_id"
generate :haml_scaffold, "post title:string"
route "map.root :controller => 'posts', :action => 'index'"
rake "db:migrate"
rake "db:fixtures:load"
file 'app/models/post.rb',
%q{class Post < ActiveRecord::Base
  has_friendly_id :title, :use_slug => true
end}
file 'test/fixtures/slugs.yml',
%q{
one:
  name: mystring
  sequence: 1
  sluggable: one (Post)

two:
  name: mystring
  sequence: 2
  sluggable: two (Post)
}
