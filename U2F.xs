#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <u2f-server.h>

MODULE = PVE::U2F		PACKAGE = PVE::U2F

#// Context creation and destruction

void
do_global_init()
	CODE:
		u2fs_global_init(0);

void
do_global_done()
	CODE:
		u2fs_global_done();

SV*
new_impl()
	CODE:
		u2fs_ctx_t *ctx = NULL;
		if (u2fs_init(&ctx) != U2FS_OK) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = newSVpv((char*)&ctx, sizeof(ctx));
		}
	OUTPUT:
		RETVAL

void
done_impl(ctx)
	SV *ctx
	CODE:
		if (ctx == &PL_sv_undef) {
			croak("u2fs xs: double free");
		} else {
			u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
			u2fs_done(*pctx);
			sv_setsv(ctx, &PL_sv_undef);
		}

#// Context initialization before registration/authentication

int
set_origin_impl(ctx, origin)
	SV *ctx
	char *origin
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		RETVAL = u2fs_set_origin(*pctx, origin);
	OUTPUT:
		RETVAL

int
set_appid_impl(ctx, appid)
	SV *ctx
	char *appid
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		RETVAL = u2fs_set_appid(*pctx, appid);
	OUTPUT:
		RETVAL

int
set_challenge_impl(ctx, challenge)
	SV *ctx
	char *challenge
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		RETVAL = u2fs_set_challenge(*pctx, challenge);
	OUTPUT:
		RETVAL

int
set_keyHandle_impl(ctx, keyHandle)
	SV *ctx
	char *keyHandle
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		RETVAL = u2fs_set_keyHandle(*pctx, keyHandle);
	OUTPUT:
		RETVAL

int
set_publicKey_impl(ctx, publicKey)
	SV *ctx
	unsigned char *publicKey
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		RETVAL = u2fs_set_publicKey(*pctx, publicKey);
	OUTPUT:
		RETVAL

#// Registration functions

int
registration_challenge_impl(ctx, outref=&PL_sv_undef)
	SV *ctx
	SV *outref
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		char *output = NULL;
		u2fs_rc rc = u2fs_registration_challenge(*pctx, &output);
		if (rc == U2FS_OK) {
			sv_setpv(outref, output);
		}
		RETVAL = rc;
	OUTPUT:
		RETVAL

int
registration_verify_impl(ctx, response, kh=&PL_sv_undef, pk=&PL_sv_undef)
	SV *ctx
	char *response
	SV *kh
	SV *pk
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		u2fs_reg_res_t *result = NULL;
		u2fs_rc rc = u2fs_registration_verify(*pctx, response, &result);
		if (rc == U2FS_OK) {
			const char *keyHandle = u2fs_get_registration_keyHandle(result);
			const char *publicKey = u2fs_get_registration_publicKey(result);
			sv_setpv(kh, keyHandle);
			sv_setpv(pk, publicKey);
			u2fs_free_reg_res(result);
		}
		RETVAL = rc;
	OUTPUT:
		RETVAL

#// Authentication functions
int
auth_challenge_impl(ctx, outref=&PL_sv_undef)
	SV *ctx
	SV *outref
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		char *output = NULL;
		u2fs_rc rc = u2fs_authentication_challenge(*pctx, &output);
		if (rc == U2FS_OK) {
			sv_setpv(outref, output);
		}
		RETVAL = rc;
	OUTPUT:
		RETVAL

int
auth_verify_impl(ctx, response, verified=&PL_sv_undef, counter=&PL_sv_undef, presence=&PL_sv_undef)
	SV *ctx
	char *response
	SV *verified
	SV *counter
	SV *presence
	CODE:
		u2fs_ctx_t **pctx = (u2fs_ctx_t**)SvPV_nolen(ctx);
		u2fs_auth_res_t *result = NULL;
		u2fs_rc rc = u2fs_authentication_verify(*pctx, response, &result);
		if (rc == U2FS_OK) {
			u2fs_rc a_verified = 0;
			uint32_t a_count = 0;
			uint8_t a_presence = 0;
			rc = u2fs_get_authentication_result(result, &a_verified, &a_count, &a_presence);
			if (rc == U2FS_OK) {
				sv_setiv(verified, a_verified);
				sv_setuv(counter, a_count);
				sv_setuv(presence, a_presence);
			}
			u2fs_free_auth_res(result);
		}
		RETVAL = rc;
	OUTPUT:
		RETVAL
