skynetroot = "../skynet/"
thread = 8
logger = nil
logpath = "."
harbor = 0
-- standalone = "0.0.0.0:2013"
-- address = "127.0.0.1:2526"
-- master = "127.0.0.1:2013"

start = "main"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap

log_dirname = "log"
log_basename = "login"

loginservice = "./service/login/?.lua;" ..
         "./service/log/?.lua;" ..
			   "./common/?.lua"

-- LUA服务所在位置
luaservice = skynetroot .. "service/?.lua;" .. loginservice
snax = loginservice

-- 用于加载LUA服务的LUA代码
lualoader = skynetroot .. "lualib/loader.lua"
preload = "./global/preload.lua"	-- run preload.lua before every lua service run

-- C编写的服务模块路径
cpath = skynetroot .. "cservice/?.so"

-- 将添加到 package.path 中的路径，供 require 调用。
lua_path = skynetroot .. "lualib/?.lua;" ..
       skynetroot .. "lualib/compat10/?.lua;" ..
       "./?.lua;" ..
		   "./lualib/?.lua;" ..
		   "./global/?.lua;" ..
		   "./service/login/?.lua"

-- 将添加到 package.cpath 中的路径，供 require 调用。
lua_cpath = skynetroot .. "luaclib/?.so;" .. "./luaclib/?.so"

-- 后台模式
--daemon = "./login.pid"

port = 8081				  -- 监听端口
debug_port = 18000  -- debug console端口
max_client = 4096

mysql_maxconn = 10					-- mysql数据库最大连接数
mysql_host = "127.0.0.1"	-- mysql数据库主机
mysql_port = 3306		-- mysql数据库端口
mysql_db = "account"		-- mysql数据库库名
mysql_user = "root"	-- mysql数据库帐号
mysql_pwd = "123456"		-- mysql数据库密码

