local analysis_response = ngx.shared.analysis_response
local host = ngx.var.host
local uri = ngx.var.uri
local response_time = tonumber(ngx.var.upstream_response_time) or 0
local time = os.date("%Y%m%d%H%M")
local key = host .. uri .. ":" .. time
local total_time = analysis_response:get(key) or 0
local new_total_time = response_time * 1000 + total_time
analysis_response:set(key,new_total_time,180)
ngx.log(ngx.NOTICE, new_total_time)
