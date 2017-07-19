local skynet = require "skynet"
local snax = require "snax"
local cluster = require "cluster"
local sprotoloader = require "sprotoloader"
local protobuf = require "protobuf"
local sharedata = require "skynet.sharedata"


skynet.start(function()
	print("Server start")
  
  -- 配置
  local cfg_data = require "config.Config"
  sharedata.new("config_data", cfg_data)

  -- 公共服务
  local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")
	local console = skynet.newservice("console")
  print(skynet.getenv("debug_port"))
	skynet.newservice("debug_console",tonumber(skynet.getenv("debug_port")))

  -- 数据库  
  local db_maxconn = tonumber(skynet.getenv("mysql_maxconn"))
  local mysql_host = skynet.getenv("mysql_host")
  local mysql_port = tonumber(skynet.getenv("mysql_port"))
  local mysql_db = skynet.getenv("mysql_db")
  local mysql_user = skynet.getenv("mysql_user")
  local mysql_pwd = skynet.getenv("mysql_pwd")
  for i = 1, db_maxconn do      
      local sqlmgr = skynet.newservice("sql_mgr")
      skynet.call(sqlmgr, "lua", "start", mysql_host, mysql_user, mysql_pwd, mysql_db, mysql_port, i)
  end
  
	local center = skynet.uniqueservice("login")
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = tonumber(skynet.getenv("login_port")),
		maxclient = tonumber(skynet.getenv("login_gate_num")),
		nodelay = true,
	})
	LOG_INFO("%s %d", "Watchdog listen on:", tonumber(skynet.getenv("login_portport")))
    
  -- 测试
  local test_proto = {utc_time = 1234}
  local proto_data = protobuf.encode("client.Heart", test_proto)
  print("proto data: "..type(proto_data).." -- "..#proto_data.."         ")
  local test_proto2 = protobuf.decode("client.Heart", proto_data)
  print("111"..test_proto2.utc_time)
  print("222"..test_proto2.time_zone)
  
  test_proto = {DstRoleId=987654321123, SrcRoleId=987654321123}
  proto_data = protobuf.encode("client.ChatMsgReq", test_proto)
  test_proto2 = protobuf.decode("client.ChatMsgReq", proto_data)
  print("len:"..#proto_data)
  print("111 "..test_proto2.DstRoleId+1)
  print("222 "..test_proto2.SrcRoleId+1)
  
  test_proto = {Name="22222", HeadIcon=33}
  proto_data = protobuf.encode("client.RoleBaseExData", test_proto)
  test_proto2 = protobuf.decode("client.RoleBaseExData", proto_data)
  print("111 "..test_proto2.HeadIcon)

  --local cfg_root = sharedata.query("config_data")
  --print(cfg_root.CharacterInfo[1][1][1].Name)

	skynet.exit()
end)
