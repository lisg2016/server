# encoding: UTF-8
import sys, os
import thread,threading
import time
import socket,select
import struct
from google.protobuf import descriptor
from google.protobuf import message
from google.protobuf import reflection
from google.protobuf import descriptor_pb2
import types

sys.path.append(".")

import random

from client.common_pb2 import *
from client.login_pb2 import *

MSG_TYPE_USE_NAME = 1

host = '127.0.0.1'
port = 8081
#agent_info = auth_rsp()

if len(sys.argv) >= 2:
    port = int(sys.argv[1])

if len(sys.argv) >= 3:
    host = sys.argv[2]

s = socket.socket()
s.connect((host,port))

objs = {}
ignore_msg_list = ['client.role_move_msg',\
'client.client_chat_msg',\
'client.npc_attack_begin',\
'client.user_guide_list',\
'client.exp_plus_data',
#'client.role_goods_msg',\
'client.role_skill_list',\
'client.role_skill_slot_list',\
'client.growth_reward_record',\
'client.mail_list_rsp',\
'client.task_msg',\
'client.ship_tech_info_list',\
'client.client_role_funcd_table'\
]

def send_msg(msg):
    if MSG_TYPE_USE_NAME:    
        msg_name = msg.DESCRIPTOR.full_name
        msg_buf = msg.SerializeToString()
        #msg_len = 1 + len(msg_name) + 1 + len(msg_buf)
        msg_len = 1 + len(msg_name) + len(msg_buf)

        msg_len_ex = struct.pack('!H', msg_len)
        #msg_name_len_ex = struct.pack('!B', len(msg_name) + 1)
        msg_name_len_ex = struct.pack('!B', len(msg_name))

        #format = '2s1s%ds%ds' % (len(msg_name)+1, len(msg_buf))    
        format = '2s1s%ds%ds' % (len(msg_name), len(msg_buf))
        s.send(struct.pack(format, msg_len_ex, msg_name_len_ex, msg_name, msg_buf))
    else:
        msg_name = msg.DESCRIPTOR.full_name
        msg_buf = msg.SerializeToString()
        msg_len = 2 + len(msg_buf)

        msg_id = battleship_msg_id.get_id_by_name(msg_name)
        msg_id = struct.pack('!H', msg_id)    

        msg_len_ex = struct.pack('!I', msg_len)    

        format = '4s2s%ds' % (len(msg_buf))    
        s.send(struct.pack(format, msg_len_ex, msg_id, msg_buf))
    

recv_attr_ = 0

def msg_proc(msg_type, msg_buf):    
    if MSG_TYPE_USE_NAME:
        msg_type = msg_type[0:len(msg_type)]    
    #print len(msg_type)
    #print len("client.time_check")

    msg_name = msg_type[len("client."):len(msg_type)]
    exec("msg = %s()" % msg_name)
    if msg:
        msg.ParseFromString(msg_buf)
        if msg_type != "client.role_move_msg_" and msg_type != "client.client_chat_msg" and msg_type != "client.npc_attack_begin" and msg_type != "client.notify_target_dir_info":
            print "Recv: " + msg_type + " Len:" + str(len(msg_buf))
            print msg

        if msg_type == "client.role_goods_msg":
            print "client.role_goods_msg"

        if msg_type == "client.LoginRsp":
            global agent_info
            agent_info = msg

            if msg.PlayerId != 0:
                global s

                s = socket.socket()
                s.connect((msg.AgentHost,msg.AgentPort))

                req = AgentLoginReq()
                req.PlayerId = msg.PlayerId
                req.LoginKey = msg.LoginKey

                send_msg(req)

        return

def socket_func():
    recv_data = ''
    while True:
        data = ''
        try:
            data = s.recv(4096)
        except:
            if len(recv_data) == 0 & len(data) == 0:
                continue
        
        recv_data += data
        while True:
            name = None
            msg = None
            msg_len = 0
            if MSG_TYPE_USE_NAME:
                if len(recv_data) < 3:
                    break

                msg_len, = struct.unpack_from("!H", recv_data, 0)
                name_len, = struct.unpack_from("!B", recv_data, 2)
                
                print "recv:::::"
                print msg_len
                print name_len
                print len(recv_data)
                
                if len(recv_data) < msg_len + 2:
                    break            
                format = "%ds%ds" % (name_len, msg_len-name_len-1)        
                name, msg, = struct.unpack_from(format, recv_data, 3)   
            else:
                if len(recv_data) < 6:
                    break

                msg_len, = struct.unpack_from("!I", recv_data, 0)
                msg_id, = struct.unpack_from("!H", recv_data, 4)
                if len(recv_data) < msg_len + 4:
                    break            
                format = "%ds" % (msg_len-2)        
                msg, = struct.unpack_from(format, recv_data, 6)        

                name = battleship_msg_id.get_name_by_id(msg_id)

            msg_proc(name, msg)            
            
            recv_data = recv_data[msg_len+4:len(recv_data)]
            
thread.start_new(socket_func, ())

while True:
    cmd = raw_input("input:")
    if 1 == 1:
        param = cmd.split()
        print param

        if param[0] == "reconnect":
            if agent_info.ret == 1:
                s = socket.socket()
                s.connect((agent_info.agent_host,agent_info.agent_port))

                req = agent_login_req()
                req.user_id = agent_info.user_id
                req.login_key = agent_info.login_key
                print '---------------------------------'
                print agent_info.agent_host,agent_info.agent_port
                print req.login_key

                send_msg(req)
   
        if param[0] == "re":
            s = socket.socket()
            s.connect(("192.168.78.29",9031))

            req = agent_login_req()
            req.user_id = 11145
            req.login_key = "123456"

            send_msg(req)

        if param[0] == "login":        
            msg = LoginReq()
            msg.Login = unicode(param[1], "gbk")
            msg.Passwd = "123456"
            msg.SvrId = 1
            if len(param) >= 3:
                msg.SvrId = int(param[2])
            send_msg(msg)
        if param[0] == "create":
            msg = CreateRoleReq()
            msg.Name = unicode(param[1], "gbk")
            send_msg(msg)

        if param[0] == "heart":        
            msg = Heart()
            send_msg(msg)

        if param[0] == "exit":
            break   
    #except:
    #    pass

print "endxxxx"
