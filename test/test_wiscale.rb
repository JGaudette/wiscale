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

end
