require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'Haml'
require 'rss'
require 'open-uri'
require 'data_mapper'

configure :development do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db.db")
end

configure :test do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/test_db.db")
end

class RssLink
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :url, Text
  property :created_at, DateTime
end

class RssItem
  include DataMapper::Resource
  property :id, Serial
  property :guid, Text
  property :read, Boolean
end


# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the table
RssLink.auto_upgrade!
RssItem.auto_upgrade!

class RRR < Sinatra::Base

  FeedInfo = Struct.new(:title, :items)

  get '/' do
    @links = RssLink.all
    haml :index
  end

  get '/new' do
    @links = RssLink.all
    haml :new
  end

  post '/create' do
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
    feed_info = rss_feed_info(url)
    @feed = feed_info.title
    @items = feed_info.items
    add_rss_items(@items)
    unless params[:all] == 'true'
      @items.reject! { |item| !RssItem.first(guid: guid_extractor(item.guid), read: true).nil? }
    end
    haml :feed
  end

  delete '/feed/:id' do
    feed = RssLink.get(params[:id])
    feed.destroy
    redirect to('/')
  end

  get '/feed_item/mark_read' do
    item = RssItem.first(guid: params[:guid])
    puts item
    item.read = true
    item.save
    redirect back
  end

  # Helpers

  def add_rss_items(items)
    items.each do |item|
      if !RssItem.get(guid: item.guid)
        RssItem.create(
            guid: guid_extractor(item.guid),
            read: false
        )
      end
    end
  end

  def guid_extractor(guid)
    guid.to_s[/\>(.*?)\<\//m, 1]
  end

  def rss_feed_info(url)
    feed_info = nil
    open(url, { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |rss|
      feed = RSS::Parser.parse(rss)
      feed_info = FeedInfo.new(feed.channel.title, feed.items)
    end
    feed_info
  end

end
