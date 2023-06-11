import Config

if config_env() == :prod do
  config :logger, 
    compile_time_purge_matching: [
      [level_lower_than: :info]
    ],
    level: :info
end
