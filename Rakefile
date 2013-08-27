file '.friendly_id' do
  sh %{git clone https://github.com/norman/friendly_id.git .friendly_id}
end

task :master => '.friendly_id' do
  Dir.chdir '.friendly_id' do
    sh %{git clean -f}
    sh %{git checkout master}
    sh %{git pull}
    sh %{yard -o ..}
  end
end

task '4.0-stable' => '.friendly_id' do
  Dir.chdir '.friendly_id' do
    sh %{git clean -f}
    sh %{git checkout 4.0-stable}
    sh %{git pull}
    sh %{yard -o ../4.0}
  end
end

task '3.x' => '.friendly_id' do
  Dir.chdir '.friendly_id' do
    sh %{git clean -f}
    sh %{git checkout 3.x}
    sh %{git pull}
    sh %{yard -o ../3.3}
  end
end

task 'doc' => [:master, '4.0-stable', '3.x'] do
  sh %{git add .}
  sh %{git commit -m 'Regenerated docs'}
  sh %{git push}
end

task :default => 'doc'
