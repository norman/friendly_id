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

task '5.0-stable' => '.friendly_id' do
  Dir.chdir '.friendly_id' do
    sh %{git clean -f}
    sh %{git checkout 5.0-stable}
    sh %{git pull}
    sh %{yard -o ../5.0}
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

task '3.3' => '.friendly_id' do
  Dir.chdir '.friendly_id' do
    sh %{git clean -f}
    sh %{git checkout 3.x}
    sh %{git pull}
    sh %{yard -o ../3.3}
  end
end

task '2.3' => '.friendly_id' do
  Dir.chdir '.friendly_id' do
    sh %{git clean -f}
    sh %{git checkout 2.3.4}
    sh %{rdoc -o ../2.3}
  end
end

task 'doc' => [:master, '5.0-stable', '4.0-stable', '3.3', '2.3'] do
  sh %{git add .}
  sh %{git commit -m 'Regenerated docs'}
  sh %{git push}
end

task :default => 'doc'
