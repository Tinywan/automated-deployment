--[[-----------------------------------------------------------------------
* |  Copyright (C) Shaobo Wan (Tinywan)
* |  Github: https://github.com/Tinywan
* |  Blog: http://www.cnblogs.com/Tinywan
* |------------------------------------------------------------------------
* |  Date: 2017/5/19 23:25
* |  Function: proxy_pass_livenode.lua
* |  Info: host = 139.224.239.21 port = 63700 auth = tinywan123456
* |  Desc: 直播节点cdn-proxy代理脚本
* |------------------------------------------------------------------------
--]]

local redis = require "resty.redis"
local LOG = ngx.log
local ERR = ngx.ERR

local uri = ngx.var.uri
local m, err = ngx.re.match(uri, "[0-9]+")
local stream_a = ""

if m then
  stream_a = m[0]
  --LOG("makcj::",m[0])
else
  if err then
     LOG(ERR, "ngx.re.match error: ", err)
     return
  end
end

local redis_host = "127.0.0.1"
local redis_port = '6379'
local redis_auth = "123456"
local redis_timeout = 1000

-- close redis
local function close_redis(red)
  if not red then
      return
  end
  local pool_max_idle_time = 10000
  local pool_size = 100
  local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)

  if not ok then
      LOG(ERR, "set redis keepalive error : ", err)
  end
end

-- read redis
local function read_redis(_host, _port, _auth, keys)
  local red = redis:new()
  red:set_timeout(redis_timeout)
  local ok, err = red:connect(_host, _port)
  if not ok then
      LOG(ERR, "connect to redis error : ", err)
  end

  local count
  count, err = red:get_reused_times()
  if 0 == count then
      ok, err = red:auth(_auth)
      if not ok then
          LOG(ERR, "failed to auth: ", err)
          return close_redis(red)
      end
  elseif err then
      LOG(ERR, "failed to get reused times: ", err)
      return close_redis(red)
  end

  red:select(1)
  local resp = nil
  resp, err = red:hget('StreamLiveNodeInnerIp:4001496639505','livenode')
  --LOG(ERR,keys.."=======livenode --------------11111111111------------- : ",resp)
  if not resp then
      LOG(ERR, keys[1] .. " get redis content error : ", err)
      return close_redis(red)
  end

  if resp == ngx.null then
      resp = nil
  end
  close_redis(red)
  return resp
end

-- get proxy url
local function read_proxy_url()
  local url_key = "StreamLiveNodeInnerIp:" .. stream_a
  local resp, err = read_redis(redis_host, redis_port, redis_auth, url_key)
  if not resp then
      LOG(ERR, "hget StreamLiveNodeInnerIp error : ", err)
      return err
  end

  if resp == ngx.null then
      LOG(ERR, "this is not redis_data : ", err)
      return nil
  end
  --LOG(ERR, "stream_id---------------------- ",resp)
  return resp
end
ngx.var.stream_id = read_proxy_url()
