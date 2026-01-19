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
  desc "List files in shared/log"
  task :logs do
    on roles(:app) do
      execute :ls, "-la", "#{shared_path}/log"
    end
  end
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

namespace :debug do
  desc "Force kill rogue puma processes"
  task :reset_puma do
    on roles(:app) do
      info "Killing rogue puma processes (hidamari_log)..."
      # Kill specifically the process found running from the wrong directory
      execute "pkill -f 'hidamari_log' || echo 'No hidamari_log processes found'"
      execute "kill -9 464547 || echo 'Process 464547 already dead'"

      info "Killing any art-clip puma..."
      execute "pkill -u rails -f art-clip || echo 'No art-clip puma found'"

      info "Cleaning up pid/socket files..."
      execute "rm -f #{shared_path}/tmp/pids/puma.pid"
      execute "rm -f #{shared_path}/tmp/pids/puma.state"
      execute "rm -f #{shared_path}/tmp/sockets/puma.sock"
    end
  end

  desc "Check server status (processes, sockets)"
  task :status do
    on roles(:app) do
      info "--- Process Check (Puma) ---"
      execute "ps aux | grep puma || echo 'Puma not running'"

      info "--- Socket Check & Permissions ---"
      execute "ls -la #{shared_path}/tmp/sockets/ || echo 'No sockets found'"
      execute "ls -ld #{shared_path}/tmp/sockets/"
      execute "ls -ld #{shared_path}/"

      info "--- Curl Check (Localhost) ---"
      execute "curl -I --unix-socket #{shared_path}/tmp/sockets/puma.sock http://localhost || echo 'Curl failed'"
    end
  end

  desc "Deep inspect Puma process"
  task :inspect_process do
    on roles(:app) do
      # Get PID of the puma process (excluding grep itself)
      pids = capture("ps aux | grep puma | grep -v grep | awk '{print $2}'").split

      if pids.empty?
        info "No puma process found."
      else
        pids.each do |pid|
          info "--- Inspecting Puma PID: #{pid} ---"
          execute "ps -p #{pid} -o pid,user,lstart,args"
          # Try to check CWD (works on Linux)
          execute "ls -l /proc/#{pid}/cwd || echo 'Cannot check CWD'"
          # Check full cmdline
          execute "cat /proc/#{pid}/cmdline | tr '\\0' ' ' || echo 'Cannot read cmdline'"
          info "-----------------------------------"
        end
      end
    end
  end

  desc "Check used puma config"
  task :puma_config_check do
    on roles(:app) do
      info "--- Running Puma Process Args ---"
      execute "ps aux | grep puma | grep -v grep | awk '{for(i=11;i<=NF;++i)printf $i\" \"}'"

      info "--- Content of shared/puma.rb ---"
      execute "cat #{shared_path}/puma.rb || echo 'shared/puma.rb not found'"
    end
  end
end

namespace :puma do
  desc "Setup systemd user service"
  task :setup_systemd do
    on roles(:app) do
      # Service definition
      service_content = <<~SERVICE
        [Unit]
        Description=Puma HTTP Server for art-clip (production)
        After=network.target

        [Service]
        Type=simple
        WorkingDirectory=#{current_path}
        Environment=RAILS_ENV=production
        Environment=PIDFILE=#{shared_path}/tmp/pids/puma.pid
        ExecStart=/home/rails/.rbenv/bin/rbenv exec bundle exec puma -C config/puma.rb
        Restart=always
        RestartSec=1
        StandardOutput=append:#{shared_path}/log/puma.access.log
        StandardError=append:#{shared_path}/log/puma.error.log

        [Install]
        WantedBy=default.target
      SERVICE

      # Create directory and upload service file
      execute :mkdir, "-p", ".config/systemd/user"
      upload! StringIO.new(service_content), ".config/systemd/user/art-clip_puma_production.service"

      # Reload and enable
      execute :systemctl, "--user", "daemon-reload"
      execute :systemctl, "--user", "enable", "art-clip_puma_production"
      info "Systemd service installed and enabled."
    end
  end

  desc "Restart Puma (Systemd --user)"
  task :restart do
    on roles(:app) do
      execute :systemctl, "--user", "restart", "art-clip_puma_production"
    end
  end

  desc "Status Puma (Systemd --user)"
  task :status do
    on roles(:app) do
      execute :systemctl, "--user", "status", "art-clip_puma_production"
    end
  end
end

after "deploy:published", "puma:restart"
