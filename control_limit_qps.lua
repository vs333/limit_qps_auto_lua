local cjson = require "cjson"
local request_method = ngx.var.request_method
local analysis_qps = ngx.shared.analysis_qps
local analysis_limit = ngx.shared.analysis_limit
local analysis_response = ngx.shared.analysis_response
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
if "GET" == request_method then
	local args = ngx.req.get_uri_args()
        if "show" == args["action"] then
		local tables = {}
		local qps_keys = analysis_qps:get_keys(0)
		-- local response_keys = analysis_response:get_keys(0)
		for i = 1, #qps_keys do
			local qps_key = qps_keys[i]
        		local qps_value = analysis_qps:get(qps_key) or 0
			table.insert(tables, {["url"]=qps_key, ["qps"]=qps_value})
		end
		for n = 1, #qps_keys do
			repeat
                                if tables[n] == nil then
                                        break
                                end
        		local response_key = qps_keys[n]
        		local response_value = analysis_response:get(response_key) or 0
			tables[n].time = response_value
			until true
		end
		if next(tables) == nil then
			ngx.say("[]")
		else
			ngx.say(table2json(tables))
		end
        elseif "limit" == args["action"] then
	local tables = {}
        local limit_keys = analysis_limit:get_keys(0)
	for i = 1,#limit_keys do
		local limit_key = limit_keys[i]
		local limit_value = analysis_limit:get(limit_key) or 40000
		table.insert(tables,{["url"]=limit_key,["limit"]=tonumber(limit_value)})
	end
	if next(tables) == nil then
		ngx.say("[]")
	else
		ngx.say(table2json(tables))
	end
	end
elseif "POST" == request_method then
        ngx.req.read_body()
	local args = ngx.req.get_post_args()
        local result = {}
	local urikey = args["urlkey"]
	local limitvalue = args["limitvalue"]
	local expiretime = tonumber(args["expiretime"]) or 120
	analysis_limit:set(urikey,limitvalue,expiretime)
        result = {["isSuccess"]=1,["message"]=urikey .. " set qps" .. limitvalue}
        ngx.say(table2json(result))
end
