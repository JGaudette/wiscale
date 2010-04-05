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

  def scale_once()
    ret_val = JSON.parse(HTTParty.get(scale_url + '/once', :query => {:action => 'get'}))
    return ret_val['body']['once']
  end

  def compute_scale_hash(mac, secret)
    once = scale_once
    hash = mac + ':' + secret + ':' + once

    Digest::MD5::hexdigest(hash)
  end

  def session_start(email, secret, mac)
    hash = compute_scale_hash(mac, secret)

    ret_val = JSON.parse(HTTParty.get(scale_url + '/session', :query => {:action => 'new', :auth => mac, :duration => '30', :hash => hash}))

    if ret_val['status'] == 0
      ret_val['body']['sessionid']
    else
      ret_val['status']
    end

  end

  def session_delete(sessionid)
    ret_val = JSON.parse(HTTParty.get(scale_url + '/session', :query => {:action => 'delete', :sessionid => sessionid}))
    ret_val['status']
  end

  # Create a new measurements record for the user
  # * email address of account owner
  # * secret password of scale masquerading as
  # * mac address of scale masquerading as
  # * timestamp (epoch time) of measurement recording
  # * weight value (in kg) of measurement
  # * percent body fat of measurement
  def meas_create(email, secret, mac, timestamp, weight, bodyfat)
    session = session_start(email, secret, mac)

    bfmass = (weight*bodyfat*10).to_i
    weight = weight * 1000

    meas_string = "{\"measures\":[{\"value\":'#{weight}',\"type\":1,\"unit\":-3},{\"value\":'#{bfmass}',\"type\":8,\"unit\":-3}]}"

    ret_val = JSON.parse(HTTParty.get(scale_url + '/measure', :query => {
      :action => 'store',
      :sessionid => session,
      :userid => userid,
      :macaddress => mac,
      :meastime => timestamp,
      :devtype => '1',
      :attribstatus => '0',
      :measures => meas_string
    }))

    ret_val
  end

  def compute_hash(email, passwd)
    once = get_once
    hash = email + ':' + Digest::MD5::hexdigest(passwd) + ':' + once

    Digest::MD5::hexdigest(hash)
  end

  def api_url
    @api_url || @api_url = 'http://wbsapi.withings.net'
  end

  def scale_url
    @scale_url || @scale_url = 'http://scalews.withings.net/cgi-bin'
  end

  def userid
    @userid
  end

  def publickey
    @publickey
  end

end

