#include "skynet.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

struct aoi_service {
};

struct aoi_service *
aoi_create(void) {
	struct aoi_service * inst = skynet_malloc(sizeof(*inst));

	return inst;
}

void
aoi_release(struct aoi_service * inst) {
	skynet_free(inst);
}

static int
aoi_cb(struct skynet_context * context, void *ud, int type, int session, uint32_t source, const void * msg, size_t sz) {
	struct aoi_service * inst = ud;

    printf("aoi recv type:%d sz:%d session:%d\n", type, sz, session);

    //int skynet_sendname(struct skynet_context * context, uint32zzzz_t source, const char * destination , int type, int session, void * msg, size_t sz);
	//void * dst = skynet_malloc(sz);
	//memcpy(dst, msg, sz);
	skynet_sendname(context, 0, "login", PTYPE_RESPONSE, session, msg, sz);

	return 1;
}

int
aoi_init(struct aoi_service * inst, struct skynet_context *ctx, const char * parm) {
    skynet_callback(ctx, inst, aoi_cb);
    //skynet_command(ctx, "REG", ".aoi");
    return 0;
}
