ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'rack/test'
require 'mocha/test_unit'
require File.expand_path '../../rrr.rb', __FILE__

class RRRTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    RssLink.auto_migrate! # reset DB
  end

  def app
    RRR.new!
  end

  def test_it_has_new_feed_button
    get '/'
    assert last_response.ok?
    assert last_response.body.include?('New Feed')
  end

  def test_it_can_add_new_feed
    get '/new'
    assert last_response.body.include?('feed_title')
    assert last_response.body.include?('feed_url')
  end

  def test_it_creates_new_feed
    assert_equal 0, RssLink.all.length
    post '/create', :feed_title => 'The title', :feed_url => 'The url'
    assert_equal 1, RssLink.all.length
    link = RssLink.get(1)
    assert_equal 'The title', link.title
    assert_equal 'The url', link.url
  end

  def test_it_shows_feed
    RssLink.create(
        title: 'The title',
        url: 'The url',
        created_at: Time.now
    )
    items = [stub(:link => 'link_1', :title => 'title_1', :description => 'description_1'),
             stub(:link => 'link_2', :title => 'title_2', :description => 'description_2'),]
    feed_info = RRR::FeedInfo.new('The title', items)
    RRR.any_instance.stubs(:rss_feed_info).with('The url').returns(feed_info)
    get '/feed/1'
    assert last_response.ok?
    assert last_response.body.include?('title_1')
    assert last_response.body.include?('description_2')
  end

  def test_it_retrieves_feed
    rss = mock('rss')
    channel = stub(title: 'A title')
    items = [mock('mock1'), mock('mock2')]
    feed = stub(channel: channel, items: items)
    OpenURI.expects(:open_uri).yields(rss)
    RSS::Parser.expects(:parse).with(rss).returns(feed)
    expected =RRR::FeedInfo.new('A title', items)
    result = app.rss_feed_info('http://example.com')
    assert_equal expected, result
  end

end