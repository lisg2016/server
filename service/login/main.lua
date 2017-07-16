local skynet = require "skynet"
local snax = require "snax"
local cluster = require "cluster"
local sprotoloader = require "sprotoloader"
local protobuf = require "protobuf"
local sharedata = require "skynet.sharedata"


skynet.start(function()
	print("Server start")
  
  local cfg_data = require "config.Config"
  sharedata.new("config_data", cfg_data)

  local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")

	local center = skynet.uniqueservice("login")

	local console = skynet.newservice("console")
	skynet.newservice("debug_console",tonumber(skynet.getenv("debug_port")))
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = tonumber(skynet.getenv("port")),
		maxclient = tonumber(skynet.getenv("max_client")),
		nodelay = true,
	})
	LOG_INFO("%s %d", "Watchdog listen on:", tonumber(skynet.getenv("port")))
  
  
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
