task :default => :spec

require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

def gemspec
  @gem_spec ||= eval( open( `ls *.gemspec`.strip ){|file| file.read } )
end

def gem_version
  gemspec.version
end

def gem_version_tag
  "v#{gem_version}"
end

def gem_name
  gemspec.name
end

def gem_file_name
  "#{gem_name}-#{gem_version}.gem"
end

namespace :git do
  desc "Create git version tag #{gem_version}"
  task :tag do
    sh "git tag -a #{gem_version_tag} -m \"Version #{gem_version}\""
  end

  desc "Push git tag to GitHub"
  task :push_tags do
    sh 'git push --tags'
  end

  desc "Create git version tag #{gem_version} and push to GitHub"
  task :submit => [:tag, :push_tags] do
    puts "Deployed to GitHub."
  end
end
