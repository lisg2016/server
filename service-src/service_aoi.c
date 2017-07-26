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

    printf("aoi recv type:%d sz:%d\n", type, sz);

	return 0;
}

int
aoi_init(struct aoi_service * inst, struct skynet_context *ctx, const char * parm) {
    skynet_callback(ctx, inst, aoi_cb);
    //skynet_command(ctx, "REG", ".aoi");
    return 0;
}
