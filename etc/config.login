include "config"

harbor = 1
standalone = "0.0.0.0:2013"
address = "127.0.0.1:2526"

service_name = "login"

-- 日志
log_dirname = "log"
log_basename = service_name

-- LUA服务所在位置
luaservice = "./service/".. service_name .. "/?.lua;" .. luaservice
snax = lua_service

lua_path = "./service/".. service_name .. "/?.lua;" .. lua_path

-- 后台模式
--daemon = "./".. service_name ..".pid"

