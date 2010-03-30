require 'helper'

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
      assert_equal 2555, client.get_last_meas
    end
  end
end
