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
    if params.length == 1
      #TODO pass params to api for things like limie
      ret_val = JSON.parse(HTTParty.get(api_url + '/measure', :query => {:action => 'getmeas', :userid => userid, :publickey => publickey}))
    else
      ret_val = JSON.parse(HTTParty.get(api_url + '/measure', :query => {:action => 'getmeas', :userid => userid, :publickey => publickey}))
    end


    if ret_val['status'] == 0
      OpenStruct.new(ret_val['body'])
    end
  end

  #TODO this should call get_meas(:limit=>1) once first todo is done
  def get_last_meas
  ret_val = JSON.parse(HTTParty.get(api_url + '/measure', :query => {:action => 'getmeas', :userid => userid, :publickey => publickey, :limit => 1}))

    if ret_val['status'] == 0
      return OpenStruct.new(ret_val['body'])
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

