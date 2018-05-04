# frozen_string_literal: true
require 'iodine'
require 'datadog/statsd'
require_relative 'handler'

# Initialisation
statsd_name = ENV['STATSD_NAME'] || 'statsd-bridge'
statsd_host = ENV['STATSD_HOST'] || '127.0.0.1'
statsd_port = ENV['STATSD_PORT']&.to_i || 18125
dogstatsd = Datadog::Statsd.new(statsd_host, statsd_port, namespace: statsd_name)

# server ENV options:: PORT, MAX_THREADs, MAX_WORKERS, TIMEOUT
Iodine::Rack.app = Handler.new(dogstatsd)
Iodine.start
