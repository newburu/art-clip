# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"

set :application, ENV.fetch("APP_NAME", "art-clip")
set :repo_url, ENV.fetch("GIT_REPO_URL", "git@github.com:newburu/art-clip.git")
set :branch, "main"

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, ENV.fetch("DEPLOY_PATH", "/var/www/art-clip")

# Default value for :linked_files is []
append :linked_files, "config/database.yml", ".env", "config/master.key"

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
