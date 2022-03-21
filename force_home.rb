require 'nokogiri'
require 'httparty'

ROKU_IP = ARGV[0]
ROKU_PORT = 8060

loop do
  resp = HTTParty.get("http://#{ROKU_IP}:#{ROKU_PORT}/query/active-app")
  if resp.dig('active_app', 'app') != 'Roku'
    puts "awp"
    HTTParty.post("http://#{ROKU_IP}:#{ROKU_PORT}/keypress/home")
    sleep 1
  end
  sleep 0.1
end
