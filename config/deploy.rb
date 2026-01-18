# config valid for current version and patch releases of Capistrano
lock "~> 3.20.0"

set :application, ENV.fetch("APP_NAME", "art-clip")
set :repo_url, ENV.fetch("GIT_REPO_URL", "git@github.com:newburu/art-clip.git")
set :branch, "main"

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, ENV.fetch("DEPLOY_PATH", "/var/www/art-clip")

# Default value for :linked_files is []
append :linked_files, ".env", "config/master.key"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", ".bundle", "public/system", "public/uploads", "storage"

# Rbenv
set :rbenv_type, :user
set :rbenv_ruby, "4.0.0"

# Puma config
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log, "#{release_path}/log/puma.error.log"
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true
set :puma_enable_linger, false
set :puma_service_unit_env_vars, %w[
  RAILS_ENV=production
]

namespace :deploy do
  desc "Upload config files to server"
  task :upload_config do
    on roles(:app) do
      if test "[ ! -d #{shared_path}/config ]"
        execute :mkdir, "-p", "#{shared_path}/config"
      end
      upload! ".env", "#{shared_path}/.env"
      upload! "config/master.key", "#{shared_path}/config/master.key"
    end
  end
  before :check, :upload_config

  desc "Create database"
  desc "Create database"
  task :db_create do
    on roles(:db) do |host|
      with rails_env: fetch(:rails_env) do
        within release_path do
          execute :bundle, :exec, :rails, "db:create"
        end
      end
    end
  end

  before "deploy:migrate", "deploy:db_create"
end
