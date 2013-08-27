file '.friendly_id' do
  sh %{git clone https://github.com/norman/friendly_id.git .friendly_id}
end

task :master => '.friendly_id' do
  Dir.chdir '.friendly_id' do
    sh %{git checkout master}
    sh %{git pull}
    sh %{yard -o ..}
  end
end

task '4.0-stable' => '.friendly_id' do
  Dir.chdir '.friendly_id' do
    sh %{git checkout 4.0-stable}
    sh %{git pull}
    sh %{yard -o ../4.0}
  end
end

task 'doc' => [:master, '4.0-stable'] do
  sh %{git add .}
  sh %{git commit -m 'Regenerated docs'}
  # sh %{git push gh-pages origin/gh-pages}
end
