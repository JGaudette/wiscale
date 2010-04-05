require 'helper'
require 'yaml'

class TestWiscaleRuby < Test::Unit::TestCase
  context "no login required" do
    should "return 0 for connected" do
      client = WiScale.new
      assert(client.get_status == 0)
    end
  end

  context "invalid login" do
    should "fail to get last measurement" do
      client = WiScale.new(:userid => '2384', :publickey => 'asdf')
      assert_equal 2555, client.get_meas()
    end

    should "succeed to get last measurement" do
      config = YAML.load_file("credentials.yml")
      client = WiScale.new(:userid => config['userid'], :publickey => config['publickey'])

      assert_not_equal 2555, client.get_meas(:limit => 1)
    end
  end

  context "user information" do
    should "fail to get user info with invalid creds" do
      client = WiScale.new(:userid => 'fake', :publickey => 'fake')
      assert_equal 247, client.get_by_userid
    end

    should "get a single users info with valid creds" do
      config = YAML.load_file("credentials.yml")
      client = WiScale.new(:userid => config['userid'], :publickey => config['publickey'])
      users = client.get_by_userid
      assert_equal config['userid'].to_i, users[0].id.to_i
    end
  end

  context "callback subscriptions" do
    should "subscribe and revoke callback information" do
      comment_str = 'testing'
      config = YAML.load_file("credentials.yml")
      client = WiScale.new(:userid => config['userid'], :publickey => config['publickey'])
      
      assert_equal 0, client.notify_subscribe('http://www.myhackerdiet.com', comment_str)
      assert_equal 0, client.notify_revoke('http://www.myhackerdiet.com')

      # Revoking again should yield return code 294 -- 'No such subscription could be deleted'
      assert_equal 294, client.notify_revoke('http://www.myhackerdiet.com')
    end

    should "subscribe and get callback information, then revoke" do
      comment_str = 'testing'
      config = YAML.load_file("credentials.yml")
      client = WiScale.new(:userid => config['userid'], :publickey => config['publickey'])
      
      assert_equal 0, client.notify_subscribe('http://www.myhackerdiet.com', comment_str)
      
      subscription = client.notify_get('http://www.myhackerdiet.com')
      assert_equal comment_str, subscription.comment

      assert_equal 0, client.notify_revoke('http://www.myhackerdiet.com')
    end
  end

  context "sessions" do
    should "start and end session" do
      config = YAML.load_file("credentials.yml")
      client = WiScale.new()

      sessionid = client.session_start('jon@digital-drip.com', config['secret'], config['mac'])
      assert_equal 0, client.session_delete(sessionid)

    end
  end

  context "create measurement" do
    should "create a new measurement" do
      config = YAML.load_file("credentials.yml")
      client = WiScale.new(:userid => config['userid'], :publickey => config['publickey'])

      ret_val = client.meas_create(config['email'], config['secret'], config['mac'], Time.now.to_i, 100, 50)
      p 'got return val of: ' + ret_val.inspect
    end
  end

end

