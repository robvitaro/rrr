require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'Haml'
require 'rss'
require 'open-uri'
require 'data_mapper'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db.db")

class RssLink
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :url, Text
  property :created_at, DateTime
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the table
RssLink.auto_upgrade!

class RRR < Sinatra::Base


  get '/' do
    @links = RssLink.all
    haml :index
  end

  get '/new' do
    @links = RssLink.all
    haml :new
  end

  post '/create' do
    puts params[:feed_title]
    @post = RssLink.create(
        title: params[:feed_title],
        url: params[:feed_url],
        created_at: Time.now
    )
    redirect to('/')
  end

  get '/feed/:id' do
    @links = RssLink.all
    url = RssLink.get(params[:id]).url
    open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}) do |rss|
      feed = RSS::Parser.parse(rss)
      @feed = feed.channel.title
      @items = feed.items
    end
    haml :feed
  end
end
