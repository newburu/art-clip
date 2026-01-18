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

namespace :debug do
  desc "Check DB tables via Rails runner"
  task :check_db_tables do
    on roles(:app) do
      # Find latest release explicitly
      releases = capture(:ls, "-1 #{releases_path}").split.sort
      if releases.empty?
        error "No releases found."
        exit 1
      end

      latest_release = releases.last
      target_path = releases_path.join(latest_release)
      info "Using latest release: #{target_path}"

      within target_path do
        with rails_env: fetch(:rails_env) do
          ruby_script = <<~RUBY
            begin
              require 'active_record'
              ActiveRecord::Base.establish_connection
              puts "Tables: \#{ActiveRecord::Base.connection.tables.join(', ')}"
              puts "Migrations: \#{ActiveRecord::SchemaMigration.all_versions.join(', ') rescue 'Failed to get migrations'}"
            rescue => e
              puts "FAILURE: \#{e.message}"
            end
          RUBY

          upload! StringIO.new(ruby_script), "#{target_path}/db_tables_check.rb"
          execute :bundle, :exec, :rails, "runner", "#{target_path}/db_tables_check.rb"
        end
      end
    end
  end
end

namespace :debug do
  desc "Check DB connection via Rails runner"
  task :check_db_connection do
    on roles(:app) do
      # Find latest release explicitly to avoid using 'current' symlink which might not exist
      releases = capture(:ls, "-1 #{releases_path}").split.sort
      if releases.empty?
        error "No releases found. Please run 'cap production deploy' at least once."
        exit 1
      end

      latest_release = releases.last
      target_path = releases_path.join(latest_release)
      info "Using latest release for debugging: #{target_path}"

      within target_path do
        with rails_env: fetch(:rails_env) do
          ruby_script = <<~RUBY
            begin
              require 'active_record'
              puts "Environment: \#{Rails.env}"
            #{'  '}
              config = ActiveRecord::Base.connection_db_config.configuration_hash
              puts "Database Config Host: \#{config[:host]}"
              puts "Database Config User: \#{config[:username]}"
            #{'  '}
              ActiveRecord::Base.establish_connection
              ActiveRecord::Base.connection.active?
              puts "SUCCESS: Connected to database!"
            rescue => e
              puts "FAILURE: \#{e.message}"
              puts "Backtrace: \#{e.backtrace.first}"
            end
          RUBY

          upload! StringIO.new(ruby_script), "#{target_path}/db_check.rb"
          execute :bundle, :exec, :rails, "runner", "#{target_path}/db_check.rb"
        end
      end
    end
  end
end
