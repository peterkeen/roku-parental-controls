require 'nokogiri'
require 'yaml'
require 'httparty'
require 'sorbet-runtime'
require 'time'

module Limit
  extend T::Sig
  extend T::Helpers
  interface!

  sig {abstract.params(app: String).returns(T::Boolean)}
  def blocked?(app)
  end
end

class ScheduleLimit < T::Struct
  extend T::Sig

  include Limit

  const :start_time, Time
  const :end_time, Time
  const :allow_apps, T::Array[String], default: []
  const :deny_apps, T::Array[String], default: []

  sig {override.params(app: String).returns(T::Boolean)}
  def blocked?(app)
    now = Time.now

    return false if now < start_time || now > end_time
    return true if deny_apps.include?(app) || deny_apps.include?('all')
    return false if allow_apps.include?(app) || allow_apps.include?('all')

    true
  end
end

class CumulativeLimit < T::Struct
  extend T::Sig

  include Limit

  const :limit_app, String
  const :limit_seconds, BigDecimal

  prop :previous_now, Time, factory: ->{ Time.now }
  prop :next_reset, Time, factory: -> { Time.now }
  prop :accumulated_seconds, BigDecimal, factory: -> { BigDecimal(0) }

  sig {override.params(app: String).returns(T::Boolean)}  
  def blocked?(app)
    return false unless app == limit_app

    now = Time.now

    if now > next_reset
      accumulated_seconds = BigDecimal(0)
      self.next_reset = Time.new(now.year, now.month, now.day + 1)
    end

    diff = BigDecimal(now - previous_now, 4)
    accumulated_seconds += diff
    self.previous_now = now

    return true if accumulated_seconds > limit_seconds

    false
  end
end

class Roku < T::Struct
  extend T::Sig

  const :ip, String
  const :port, Integer, default: 8060

  sig { returns(String) }
  def current_app
    resp = HTTParty.get("http://#{ip}:#{port}/query/active-app")
    app = resp.dig('active_app', 'app')
    app.is_a?(String) ? app : app.dig('__content__')
  end

  sig { void }
  def send_home_key
    HTTParty.post("http://#{ip}:#{port}/keypress/home")
  end
end

LIMITS = [
  ScheduleLimit.new(start_time: Time.parse('17:30:00'), end_time: Time.parse('19:00:00'), allow_apps: ['Spotify']),
  ScheduleLimit.new(start_time: Time.parse('21:45:00'), end_time: Time.parse('23:59:59'), allow_apps: ['all'], deny_apps: ['Paramount Plus']),
  CumulativeLimit.new(limit_app: 'YouTube', limit_seconds: BigDecimal(60*30))
]

ROKUS = ARGV.map do |arg|
  ip, port = arg.split(':', 2)
  Roku.new(ip: ip, port: port.to_i)
end

loop do
  ROKUS.each do |roku|
    app = roku.current_app
    if app != 'Roku'
      LIMITS.each do |limit|
        if limit.blocked?(app)
          puts "#{app} blocked by #{limit.serialize}"
          roku.send_home_key
          sleep 1
        end
      end
    end
    sleep 0.1
  end
end
