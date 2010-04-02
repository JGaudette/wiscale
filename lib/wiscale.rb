require 'rubygems'
require 'httparty'
require 'json'
require 'ostruct'


class WiScale

  def initialize(*params)
    @publickey = params[0][:publickey] if params.length > 0
    @userid  = params[0][:userid]  if params.length > 0
  end

  def get_status()
    ret_val = JSON.parse(HTTParty.get(api_url + '/once', :query => {:action => 'probe'}))
    return ret_val['status']
  end

  def get_once()
    ret_val = JSON.parse(HTTParty.get(api_url + '/once', :query => {:action => 'get'}))
    return ret_val['body']['once']
  end

  def get_meas(*params)
    params = Array.new unless params
    params[0] = Hash.new unless params[0]

    params[0][:action] = 'getmeas'
    params[0][:userid] = userid
    params[0][:publickey] = publickey

    ret_val = JSON.parse(HTTParty.get(api_url + '/measure', :query => params[0]))

    if ret_val['status'] == 0
      measures = ret_val['body']['measuregrps'].collect { |meas| OpenStruct.new(meas) }
      OpenStruct.new({:updatetime => ret_val['body']['updatetime'], :measures => measures})
    else
      ret_val['status']
    end
  end

  def get_by_userid
    ret_val = JSON.parse(HTTParty.get(api_url + '/user', :query => {
      :action => 'getbyuserid',
      :userid => userid,
      :publickey => publickey}))

    if ret_val['status'] == 0
      ret_val['body']['users'].collect { |user| OpenStruct.new(user) }
    else
      ret_val['status']
    end
  end

  def api_url
    @api_url || @api_url = 'http://wbsapi.withings.net'
  end

  def userid
    @userid
  end

  def publickey
    @publickey
  end

end

