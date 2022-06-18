unless ENV['RAILS_ENV'] == 'development'
  # Change to match your CPU core count
  workers ENV['CPU_CORES'] || 2

  # Min and Max threads per worker
  threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 10)
  threads threads_count, threads_count

  app_dir = File.expand_path("../..", __FILE__)
  tmp_dir = "#{app_dir}/tmp"

  # Default to production
  environment ENV['RAILS_ENV'] || "production"
  daemonize true

  # Set up socket location
  bind "unix://#{tmp_dir}/sockets/puma.sock"

  # Logging
  stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true

  # Set master PID and state locations
  pidfile "#{tmp_dir}/pids/puma.pid"
  state_path "#{tmp_dir}/pids/puma.state"
  activate_control_app

  preload_app!

  on_worker_boot do |worker_id|
    File.open("#{tmp_dir}/pids/worker_#{worker_id}.pid", "w") { |f| f.puts Process.pid }

    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.establish_connection
    end
  end

  # possible script for monit / start stop puma https://gist.github.com/sudara/8653130
  # OR: https://coderwall.com/p/7nqkvw/puma-cluster-and-monit-respawn-workers-on-exceeding-memory-limit
end