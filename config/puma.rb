# config/puma.rb

unless ENV['RAILS_ENV'] == 'development'
  # === Concurrency ===
  workers Integer(ENV['CPU_CORES'] || 2)

  threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 10)
  threads threads_count, threads_count

  # === Paths / Environment ===
  app_dir = File.expand_path("../..", __FILE__)
  tmp_dir = "#{app_dir}/tmp"
  environment ENV['RAILS_ENV'] || "production"

  # Puma 6+: no daemon mode. Use a supervisor (systemd) instead.
  # daemonize true  # ❌ removed

  # === Sockets / PIDs / State ===
  bind "unix://#{tmp_dir}/sockets/puma.sock"
  pidfile "#{tmp_dir}/pids/puma.pid"
  state_path "#{tmp_dir}/pids/puma.state"

  # === Logging ===
  # If you run under systemd, consider logging to stdout/stderr instead of redirecting.
  stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true

  # === Control app for pumactl ===
  # Use a dedicated control socket and token.
  activate_control_app "unix://#{tmp_dir}/sockets/pumactl.sock",
                       { auth_token: ENV.fetch('PUMA_CTL_TOKEN', 'changeme') }

  # === Preload & Boot ===
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