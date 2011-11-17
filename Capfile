$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, 'jruby-1.6.3@tykebot'
set :rvm_type, :user

require 'rubygems'
require 'railsless-deploy'
require 'capistrano/ext/multistage'
require 'capistrano/recipes/deploy/strategy/copy'

set :application, 'tykebot'

#default_run_options[:pty] = true
default_run_options[:pty] = false
set :use_sudo, false
set :scm, :git
set :remote, 'origin'
set :deploy_via, :remote_cache
set :repository, 'git://github.com/tykeal/TykeBot.git'
# Force the deploys to always go as the tykebot user
set :user, variables[:user].nil? ? 'tykebot' : variables[:user]
set :copy_exclude, [".git/*", ".git*", "Capfile", "config/deploy"]
ssh_options[:paranoid] = false
ssh_options[:forward_agent] = false

set :deploy_to, "/home/#{user}/deploy/#{application}"
set :shared_children, fetch(:shared_children) + [ "config", "log", "data" ]
set :template_files, ['startup/botservice.sh']

set (:local_version) { `cat .git/refs/heads/#{branch rescue 'master'}`.strip }

namespace :deploy do
  [:start, :stop, :restart].each do |t|
    task t do
      run "#{current_path}/startup/botservice.sh #{t}"
    end
  end

  task :template do
    (variables[:template_files]||[]).each do |f|
      # do replacement
      erb=ERB.new open(f){|file| file.read}
      put erb.result(binding), "#{release_path}/#{f}"
    end
  end

  task :bundleinstall do
    run "cd #{current_path}; gem list | grep -q [b]undler; if [ $? ]; then echo 'bundler already installed' ;else gem install bundler; fi"
    run "cd #{current_path} && bundle install"
  end

  task :symlink, :except => { :no_release => true } do
    on_rollback do
      if previous_release
        run "rm -f #{current_path}; ln -s #{previous_release} #{current_path}; true"
      else
        logger.important "no previous release to rollback to, rollback of symlink skipped"
      end
    end

    run "ln -sfn #{latest_release} #{current_path}" 
    run "ln -sfn #{shared_path}/config/bardic.yaml #{latest_release}/config/bardic.yaml"
    run "ln -sfn #{shared_path}/log #{latest_release}/"
    run "rm -rf #{latest_release}/data && ln -sfn #{shared_path}/data #{latest_release}/"
  end
end

namespace :rvm do
  task :trust_rvmrc do
    run "rvm rvmrc trust #{release_path}"
  end
end

after "deploy", "deploy:cleanup"
after "deploy:symlink", "rvm:trust_rvmrc", "deploy:restart"
after "rvm:trust_rvmrc", "deploy:bundleinstall"
after "deploy:bundleinstall", "deploy:template"

# vim:ts=2:sw=2:expandtab:ft=ruby
