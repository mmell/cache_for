require 'cache_for'
require 'time'
require 'redis'
require 'uri'

module CacheFor

  class Base
    attr_accessor :for_seconds

    DefaultSeconds = 600 # 10 minutes
    DefaultUri = URI::parse("redis://localhost:6379")
    CacheMiss = nil

    def initialize(redis_uri = nil, default_seconds: Base::DefaultSeconds)
      redis_uri = to_uri(redis_uri)
      redis_store = Redis.new( host: redis_uri.host, port: redis_uri.port )
      @redis_store, @for_seconds = redis_store, default_seconds
    end

    def to_uri(obj = DefaultUri)
      obj = DefaultUri if obj.nil?
      obj = URI::parse(obj) unless obj.respond_to?(:host)
      obj
    end

    def get(name, seconds = nil)
      begin
        if found = @redis_store.get(key_for(name, seconds))
          puts "cache hit #{key_for(name, seconds)}"
          found
        end
      rescue
        puts "cache miss #{key_for(name, seconds)}"
        self.class::CacheMiss
      end
    end
    alias_method :read, :get

    def set(name, value, seconds = nil)
      begin
        @redis_store.set(key_for(name, seconds), value)
      rescue
      end
    end
    alias_method :write, :set

    def expire(name, seconds = nil)
      begin
        @redis_store.expire(key_for(name, seconds))
      rescue
      end
    end

    def cache_time(seconds = nil)
      seconds ||= for_seconds
      # a time integer that remains unchanging for <seconds> seconds
      #   rounds down to nearest multiple of seconds
      (seconds * (Time.now.to_i / seconds).to_i)
    end

    def key_for(name, seconds = nil)
      "#{name}#{cache_time(seconds)}"
    end

    def cacheable?(val)
      begin
        !(val.nil? or val.empty?)
      rescue
        true
      end
    end

    def fetch(name, seconds = nil)
      cached = get(name, seconds)
      if cacheable?(cached)
        cached
      else
        new_value = yield
        if cacheable?(new_value)
          set(name, new_value, seconds)
          expire(name, seconds)
        end
        new_value
      end
    end

  end

end
