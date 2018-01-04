local function close_redis(redis_instance)
	if not redis_instance then
		return
	end
	local ok,err = redis_instance:close();
	if not ok then
		ngx.say("close redis error : ",err);
	end
end

local redis = require("resty.redis");
--local redis = require "redis"
-- 创建一个redis对象实例。在失败，返回nil和描述错误的字符串的情况下
local redis_instance = redis:new();
--设置后续操作的超时（以毫秒为单位）保护，包括connect方法
redis_instance:set_timeout(1000)
--建立连接
local ip = '127.0.0.1'
local port = 6379
--尝试连接到redis服务器正在侦听的远程主机和端口
local ok,err = redis_instance:connect(ip,port)
if not ok then
	ngx.say("connect redis error : ",err)
	return close_redis(redis_instance);
end

--Redis身份验证
--local auth,err = redis_instance:auth("");
--if not auth then
--	ngx.say("failed to authenticate : ",err)
--end

--调用API进行处理
local resp,err = redis_instance:set("msg","hello worTnywan")
if not resp then
	ngx.say("set msg error : ",err)
	return close_redis(redis_instance)
end

--调用API获取数据  
local resp, err = redis_instance:get("msg")  
if not resp then  
    ngx.say("get msg error : ", err)  
    return close_redis(redis_instance)  
end 

--得到的数据为空处理  
if resp == ngx.null then  
    resp = 'this is not redis_data'  --比如默认值  
end  
ngx.say("msg : ", resp)  
  
close_redis(redis_instance)



