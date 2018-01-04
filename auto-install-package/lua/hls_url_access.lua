-- access
local var = ngx.var
local stream_name = var.stream_name
ngx.say("access.lua ::",stream_name)
