.PHONY: all skynet clean

PLAT ?= linux
SHARED := -fPIC --shared
LUA_CLIB_PATH ?= luaclib
LUA_INC ?= ../skynet/3rd/lua
CSERVICE_PATH ?= cservice
SKYNET_PATH ?= ../skynet/skynet-src

CFLAGS = -g3 -O0 -Wall -I$(LUA_INC) -I$(SKYNET_PATH)

LUA_CLIB = protobuf log
CSERVICE = aoi

#all : skynet

#skynet/Makefile :
#	git submodule update --init

#skynet : skynet/Makefile
#	cd skynet && $(MAKE) $(PLAT) && cd ..

all : \
	$(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) \
	$(foreach v, $(CSERVICE), $(CSERVICE_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(CSERVICE_PATH) :
	mkdir $(CSERVICE_PATH)

$(LUA_CLIB_PATH)/protobuf.so : | $(LUA_CLIB_PATH)
	cd lualib-src/pbc && $(MAKE) lib && cd binding/lua53 && $(MAKE) && cd ../../../.. && cp lualib-src/pbc/binding/lua53/protobuf.so $@

$(LUA_CLIB_PATH)/log.so : lualib-src/lua-log.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(CSERVICE_PATH)/aoi.so : service-src/service_aoi.c | $(CSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

clean :	
	rm -rf cservice && rm -rf luaclib && cd lualib-src/pbc && $(MAKE) clean
