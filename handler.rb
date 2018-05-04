# frozen_string_literal: true
require 'iodine/json'

class Handler
  STATS_PATH = '/stats'
  JSON_CONTENT_TYPE = 'application/json'

  NOT_FOUND = [404, {}, []].freeze
  UNSUPPORTED_METHOD = [405, {}, []].freeze
  BAD_REQUEST = [400, {}, []].freeze
  ACCEPTED = [202, {}, []].freeze

  def initialize(dogstatsd)
    @dogstatsd = dogstatsd
  end

  # request body:
  #   {
  #      count: [
  #        ['stat_name', amount],
  #        ...
  #      ],
  #      gauge: [
  #        ['stat_name', value],
  #        ...
  #      ],
  #      timing: [
  #        ['stat_name', milliseconds],
  #        ...
  #      ],
  #      tags: [
  #        'tag:value',
  #        ...
  #      ]
  #   }
  def call(env)
    if env['rack.upgrade?'] == :websocket
      env['rack.upgrade'] = self
      return [0,{}, []]
    end

    return NOT_FOUND unless env['PATH_INFO'] == STATS_PATH
    return UNSUPPORTED_METHOD unless env['REQUEST_METHOD'] == 'POST'
    return BAD_REQUEST unless env['CONTENT_TYPE'] == JSON_CONTENT_TYPE

    operations = Iodine::JSON.parse!(env['rack.input'].read)
    tags = operations[:tags] || []
    operations.slice(:count, :gauge, :timing).each_pair do |op, stats|
      stats.each do |(stat_name, value)|
        dogstatsd.public_send(op, stat_name.to_s, value.to_f, tags: tags)
      end
    end

    ACCEPTED
  rescue => e
    puts e.message
    BAD_REQUEST
  end

  # data format:
  #   "operation stat_name value *tags" (space-separate)
  def on_message(data)
    op, stat, value, *tags = data.split(' ')
    if stat && value && (op == 'count' || op == 'gauge' || op == 'timing')
      dogstatsd.public_send(op, stat, value.to_i, tags: tags)
      write '1'
    end
  rescue => e
    puts e.message
  end
end
