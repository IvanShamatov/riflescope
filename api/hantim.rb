require 'eventmachine'
require 'thin'
require 'em-http-request'
require 'json'
require 'redis'

EM.run do 
  redis = Redis.new(driver: :hiredis)
  urls = []
  [*1..16].each do |i|
    urls << "http://hantim.ru/jobs.json?q=ruby&page=#{i}"
  end
  puts urls.inspect
  urls.each do |url|
    http = EventMachine::HttpRequest.new(url, :connect_timeout => 1)
    req = http.get
    req.callback do 
      vacs = JSON.parse(req.response)
      vacs.each do |vac|
        redis.pipelined do 
          redis.set "vac:#{vac["id"]}", vac.to_json
        end
      end
    end
  end

end