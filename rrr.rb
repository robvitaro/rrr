require 'sinatra'
require 'sinatra/base'
require 'Haml'
require 'rss'
require 'open-uri'

class RRR < Sinatra::Base
  get '/' do
    @title = "rrr (rob's rss reader)"
    url = 'http://www.tor.com/feed'
    open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      @feed = "Title: #{feed.channel.title}"
      @items = feed.items
    end
    haml :index
  end
end
