require 'eventmachine'
require 'sinatra/base'
require 'thin'
require 'em-http-request'
require 'json'
require 'redis'

module Rifle

  def self.redis
    @redis ||= Redis.new(driver: :hiredis)
  end


  class Server < Sinatra::Base
    configure do
      set :threaded, false
    end

    get '/:lang' do
      headers('Access-Control-Allow-Origin' => "*")
      redis = Rifle.redis
      resp = redis.get(params[:lang])
      if resp.nil?
        http = EM::HttpRequest.new("http://hantim.ru/jobs.json").get( query: {'q' => params[:lang]} )
        puts "Request to get #{params[:lang]} vacancies"
        resp = http.callback do 
          response = http.response
          redis.pipelined do
            redis.set http.req.query["q"], response
            redis.incr 'counter'
          end
        end
        puts resp.inspect
      else
        resp
      end
      resp
    end
 
  end


  EM.run do
    Thin::Server.start Server, '0.0.0.0', 8000
  end

end