require 'rubygems'
require 'httparty'
require 'json'
require 'ostruct'
require 'digest/md5'

# See API documentation for more information on return values
# http://www.withings.com/en/api/bodyscale
#
# OpenStruct used when returning the 'body' information from api
# Individual sub-measurements are returned as array of hashes
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

  def notify_subscribe(callbackurl, comment)
    ret_val = JSON.parse(HTTParty.get(api_url + '/notify', :query => {
      :action => 'subscribe',
      :userid => userid,
      :publickey => publickey,
      :callbackurl => URI.encode(callbackurl),
      :comment => comment
    }))

    ret_val['status']
  end

  def notify_revoke(callbackurl)
    ret_val = JSON.parse(HTTParty.get(api_url + '/notify', :query => {
      :action => 'revoke',
      :userid => userid,
      :publickey => publickey,
      :callbackurl => URI.encode(callbackurl)
    }))

    ret_val['status']
  end

  def notify_get(callbackurl)
    ret_val = JSON.parse(HTTParty.get(api_url + '/notify', :query => {
      :action => 'get',
      :userid => userid,
      :publickey => publickey,
      :callbackurl => URI.encode(callbackurl)
    }))

    if ret_val['status'] == 0
      OpenStruct.new(ret_val['body'])
    else
      ret_val['status']
    end
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

