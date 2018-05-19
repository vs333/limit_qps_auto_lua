function table2json(t)
        local function serialize(tbl)
                local tmp = {}
                for k, v in pairs(tbl) do
                        local k_type = type(k)
                        local v_type = type(v)
                        local key = (k_type == "string" and "\"" .. k .. "\":")
                            or (k_type == "number" and "")
                        local value = (v_type == "table" and serialize(v))
                            or (v_type == "boolean" and tostring(v))
                            or (v_type == "string" and "\"" .. v .. "\"")
                            or (v_type == "number" and v)
                        tmp[#tmp + 1] = key and value and tostring(key) .. tostring(value) or nil
                end
                if table.maxn(tbl) == 0 then
                        return "{" .. table.concat(tmp, ",") .. "}"
                else
                        return "[" .. table.concat(tmp, ",") .. "]"
                end
        end
        assert(type(t) == "table")
        return serialize(t)
end
local analysis_qps = ngx.shared.analysis_qps
local analysis_qps_by_sec = ngx.shared.analysis_qps_by_sec
local analysis_limit = ngx.shared.analysis_limit
local host = ngx.var.host
local uri = ngx.var.uri
local time_by_sec = os.date("%Y%m%d%H%M%S")
local time_by_min = os.date("%Y%m%d%H%M")
local key_by_sec = host .. uri .. ":" .. time_by_sec
local key_by_min = host .. uri .. ":" .. time_by_min
local limit_qps = analysis_limit:get(host .. uri) or 20000
local real_qps_by_min = analysis_qps:get(key_by_min) or 0
local real_qps_by_sec = analysis_qps_by_sec:get(key_by_sec) or 0
if tonumber(real_qps_by_sec) < tonumber(limit_qps)/60 then
    local now_real_qps_by_sec = real_qps_by_sec + 1
    local now_real_qps_by_min = real_qps_by_min + 1
        ngx.log(ngx.NOTICE, now_real_qps)
    analysis_qps:safe_set(key_by_min,now_real_qps_by_min,180)
    analysis_qps_by_sec:safe_set(key_by_sec,now_real_qps_by_sec,10)
else
    local tables = {["count"]=0,["login"]=0,["isSuccess"]=0,["isRedirect"]=0,["msg"]="系统拥挤，请稍后重试~",["errorCode"]=666,["code"]=0}
    ngx.header.content_type = "application/json;charset=utf8";
    ngx.log(ngx.NOTICE, "触发限流")
    ngx.say(table2json(tables))
    ngx.exit(200)
end
