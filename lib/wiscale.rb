require 'rubygems'
require 'httparty'
require 'json'
require 'ostruct'
require 'digest/md5'

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

  def get_users_list(email, passwd)
    hash = compute_hash(email, passwd)
    ret_val = JSON.parse(HTTParty.get(api_url + '/account', :query => {:action => 'getuserslist', :email => email, :hash => hash}))

    if ret_val['status'] == 0
      ret_val['body']['users'].collect { |user| OpenStruct.new(user) }
    else
      ret_val['status']
    end
  end

  def user_update(ispublic)
    ret_val = JSON.parse(HTTParty.get(api_url + '/user', :query => {:action => 'update', :userid => userid, :publickey => publickey, :ispublic => ispublic}))

    ret_val['status']
  end

    ret_val['status']
  end

  def compute_hash(email, passwd)
    once = get_once
    hash = email + ':' + Digest::MD5::hexdigest(passwd) + ':' + once

    Digest::MD5::hexdigest(hash)
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

