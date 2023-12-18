

all:

-include config.mk

export ROOT_DIR = $(PWD)
export BUILD_BASE_DIR = $(ROOT_DIR)/.build
export PREAMBLE = $(BUILD_BASE_DIR)/preamble.mk

include $(PREAMBLE)

ifndef $(VPFX)_ENV
export $(VPFX)_ENV = default
endif

# NOTE: This allows callers to override install location
LUAROCKS ?= luarocks

ifdef $(VPFX)_WASM
export $(VPFX)_WASM
export CLIENT_VARS = CC="emcc" CXX="em++" AR="emar" LD="emcc" NM="llvm-nm" LDSHARED="emcc" RANLIB="emranlib"
export BUILD_DIR = $(BUILD_BASE_DIR)/$($(VPFX)_ENV)-wasm
export CC = emcc
export CXX = em++
export AR = emar
export NM = llvm-nm
export LDSHARED = emcc
export RANLIB = emranlib
else
export BUILD_DIR = $(BUILD_BASE_DIR)/$($(VPFX)_ENV)
endif

TOKU_TEMPLATE = BUILD_DIR="$(BUILD_DIR)" toku template -M -c $(ROOT_DIR)/config.lua
export TOKU_TEMPLATE_TEST = TEST=1 $(TOKU_TEMPLATE)
ROCKSPEC = $(BUILD_DIR)/$(NAME)-$(VERSION).rockspec

LIB = $(shell find lib -type f 2>/dev/null)
BIN = $(shell find bin -type f 2>/dev/null)
TEST_SPEC = $(shell find test/spec -type f 2>/dev/null)
TEST_OTHER = $(filter-out $(TEST_SPEC), $(shell find test -type f 2>/dev/null))
RES = $(shell find res -type f 2>/dev/null)
DEPS = $(shell find deps -type f 2>/dev/null)

LUAROCKS_MK = $(BUILD_DIR)/Makefile

ifneq ($(LIB),)
LIB_MK = $(BUILD_DIR)/lib/Makefile
endif

ifneq ($(BIN),)
BIN_MK = $(BUILD_DIR)/bin/Makefile
endif

TEST_LIB_MK = $(BUILD_DIR)/test/lib/Makefile
TEST_BIN_MK = $(BUILD_DIR)/test/bin/Makefile
TEST_ROCKSPEC = $(BUILD_DIR)/test/$(NAME)-$(VERSION).rockspec
export TEST_LUAROCKS = LUAROCKS_CONFIG=$(TEST_LUAROCKS_CFG) luarocks
TEST_LUAROCKS_CFG = $(BUILD_DIR)/test/luarocks.lua
TEST_LUAROCKS_MK = $(BUILD_DIR)/test/Makefile
TEST_ENV = $(BUILD_DIR)/test/lua.env
export TEST_LUACOV_CFG = $(BUILD_DIR)/test/luacov.lua
export TEST_LUACOV_STATS_FILE = $(BUILD_DIR)/test/luacov.stats.out
export TEST_LUACOV_REPORT_FILE = $(BUILD_DIR)/test/luacov.report.out
TEST_LUACHECK_CFG = $(BUILD_DIR)/test/luacheck.lua

PREAMBLE_DATA = ZXhwb3J0IE5BTUUgPSA8JSByZXR1cm4gbmFtZSAlPgpleHBvcnQgVkVSU0lPTiA9IDwlIHJldHVybiB2ZXJzaW9uICU+CmV4cG9ydCBWUEZYID0gPCUgcmV0dXJuIHZhcmlhYmxlX3ByZWZpeCAlPgpleHBvcnQgJChWUEZYKV9QVUJMSUMgPSA8JSByZXR1cm4gcHVibGljIGFuZCAiMSIgb3IgIjAiICU+Cg==
ROCKSPEC_DATA = PCUgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKSAlPgo8JSBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpICU+CgpwYWNrYWdlID0gIjwlIHJldHVybiBuYW1lICU+Igp2ZXJzaW9uID0gIjwlIHJldHVybiB2ZXJzaW9uICU+Igpyb2Nrc3BlY19mb3JtYXQgPSAiMy4wIgoKc291cmNlID0gewogIHVybCA9ICI8JSByZXR1cm4gZG93bmxvYWQgJT4iLAp9CgpkZXNjcmlwdGlvbiA9IHsKICBob21lcGFnZSA9ICI8JSByZXR1cm4gaG9tZXBhZ2UgJT4iLAogIGxpY2Vuc2UgPSAiPCUgcmV0dXJuIGxpY2Vuc2Ugb3IgJ1VOTElDRU5TRUQnICU+Igp9CgpkZXBlbmRlbmNpZXMgPSB7CiAgPCUgcmV0dXJuIHZlYy53cmFwKGRlcGVuZGVuY2llcyBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9CgpidWlsZCA9IHsKICB0eXBlID0gIm1ha2UiLAogIG1ha2VmaWxlID0gIk1ha2VmaWxlIiwKICB2YXJpYWJsZXMgPSB7CiAgICBMSUJfRVhURU5TSU9OID0gIiQoTElCX0VYVEVOU0lPTikiLAogIH0sCiAgYnVpbGRfdmFyaWFibGVzID0gewogICAgQ0MgPSAiJChDQykiLAogICAgQ0ZMQUdTID0gIiQoQ0ZMQUdTKSIsCiAgICBMSUJGTEFHID0gIiQoTElCRkxBRykiLAogICAgTFVBX0JJTkRJUiA9ICIkKExVQV9CSU5ESVIpIiwKICAgIExVQV9JTkNESVIgPSAiJChMVUFfSU5DRElSKSIsCiAgICBMVUFfTElCRElSID0gIiQoTFVBX0xJQkRJUikiLAogICAgTFVBID0gIiQoTFVBKSIsCiAgfSwKICBpbnN0YWxsX3ZhcmlhYmxlcyA9IHsKICAgIElOU1RfUFJFRklYID0gIiQoUFJFRklYKSIsCiAgICBJTlNUX0JJTkRJUiA9ICIkKEJJTkRJUikiLAogICAgSU5TVF9MSUJESVIgPSAiJChMSUJESVIpIiwKICAgIElOU1RfTFVBRElSID0gIiQoTFVBRElSKSIsCiAgICBJTlNUX0NPTkZESVIgPSAiJChDT05GRElSKSIsCiAgfQp9Cgo8JSB0ZW1wbGF0ZTpwdXNoKG9zLmdldGVudigiVEVTVCIpID09ICIxIikgJT4KCnRlc3RfZGVwZW5kZW5jaWVzID0gewogIDwlIHJldHVybiB2ZWMud3JhcCh0ZXN0X2RlcGVuZGVuY2llcyBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9Cgp0ZXN0ID0gewogIHR5cGUgPSAiY29tbWFuZCIsCiAgY29tbWFuZCA9ICJtYWtlIHRlc3QiCn0KCjwlIHRlbXBsYXRlOnBvcCgpICU+Cg==

LUAROCKS_MK_DATA = ZXhwb3J0IFZQRlggPSA8JSByZXR1cm4gdmFyaWFibGVfcHJlZml4ICU+CgpERVBTX0RJUlMgPSAkKHNoZWxsIGZpbmQgZGVwcy8qIC1tYXhkZXB0aCAwIC10eXBlIGQgMj4vZGV2L251bGwpCkRFUFNfUkVTVUxUUyA9ICQoYWRkc3VmZml4IC9yZXN1bHRzLm1rLCAkKERFUFNfRElSUykpCgppbmNsdWRlICQoREVQU19SRVNVTFRTKQoKYWxsOiAkKERFUFNfUkVTVUxUUykgJChURVNUX1JVTl9TSCkKCUBpZiBbIC1kIGxpYiBdOyB0aGVuICQoTUFLRSkgLUMgbGliIFBBUkVOVF9ERVBTX1JFU1VMVFM9IiQoREVQU19SRVNVTFRTKSI7IGZpCglAaWYgWyAtZCBiaW4gXTsgdGhlbiAkKE1BS0UpIC1DIGJpbiBQQVJFTlRfREVQU19SRVNVTFRTPSIkKERFUFNfUkVTVUxUUykiOyBmaQoKaW5zdGFsbDogYWxsCglAaWYgWyAtZCBsaWIgXTsgdGhlbiAkKE1BS0UpIC1DIGxpYiBpbnN0YWxsOyBmaQoJQGlmIFsgLWQgYmluIF07IHRoZW4gJChNQUtFKSAtQyBiaW4gaW5zdGFsbDsgZmkKCjwlIHRlbXBsYXRlOnB1c2gob3MuZ2V0ZW52KCJURVNUIikgPT0gIjEiKSAlPgoKVEVTVF9SVU5fU0ggPSBydW4uc2gKCnRlc3Q6ICQoVEVTVF9SVU5fU0gpICQoV0FTTV9URVNUUykKCXNoICQoVEVTVF9SVU5fU0gpCgokKFRFU1RfUlVOX1NIKTogJChQUkVBTUJMRSkKCUBlY2hvICJHZW5lcmF0aW5nICckQCciCglAc2ggLWMgJ2VjaG8gJChURVNUX1JVTl9TSF9EQVRBKSB8IGJhc2U2NCAtZCB8ICQoVE9LVV9URU1QTEFURV9URVNUKSAtZiAtIC1vICIkQCInCgokKEJVSUxEX0RJUikvdGVzdC9zcGVjLWJ1bmRsZWQvJTogJChCVUlMRF9ESVIpL3Rlc3Qvc3BlYy8lLmx1YQoJZWNobyAiQnVuZGxpbmcgJyQ8JyAtPiAnJChwYXRzdWJzdCAlLmx1YSwlLCAkPCknIgoJbWtkaXIgLXAgIiQocGF0c3Vic3QgJChCVUlMRF9ESVIpL3Rlc3Qvc3BlYy8lLCQoQlVJTERfRElSKS90ZXN0L3NwZWMtYnVuZGxlci8lLCAkKGRpciAkPCkpIgoJJChDTElFTlRfVkFSUykgdG9rdSBidW5kbGUgXAoJCS0tZW52ICQoVlBGWClfU0FOSVRJWkUgIiQoJChWUEZYKV9TQU5JVElaRSkiIFwKCQktLWVudiBMVUFDT1ZfQ09ORklHICIkKFRFU1RfTFVBQ09WX0NGRykiIFwKCQktLXBhdGggIiQoc2hlbGwgJChURVNUX0xVQVJPQ0tTKSBwYXRoIC0tbHItcGF0aCkiIFwKCQktLWNwYXRoICIkKHNoZWxsICQoVEVTVF9MVUFST0NLUykgcGF0aCAtLWxyLWNwYXRoKSIgXAoJCS0tbW9kIGx1YWNvdiBcCgkJLS1tb2QgbHVhY292Lmhvb2sgXAoJCS0tbW9kIGx1YWNvdi50aWNrIFwKCQktLWlnbm9yZSBkZWJ1ZyBcCgkJLS1jYyBlbWNjIFwKCQktLWZsYWdzICIgLXNBU1NFUlRJT05TIC1zU0lOR0xFX0ZJTEUgLXNBTExPV19NRU1PUllfR1JPV1RIIC1sbm9kZWZzLmpzIC1sbm9kZXJhd2ZzLmpzIiBcCgkJLS1mbGFncyAiICQoTElCX0NGTEFHUykgJChMSUJfTERGTEFHUykiIFwKCQktLWZsYWdzICIgLUkgJChDTElFTlRfTFVBX0RJUikvaW5jbHVkZSIgXAoJCS0tZmxhZ3MgIiAtTCAkKENMSUVOVF9MVUFfRElSKS9saWIiIFwKCQktLWZsYWdzICIgLWwgbHVhIiBcCgkJLS1mbGFncyAiIC1sIG0iIFwKCQktLWlucHV0ICIkPCIgXAoJCS0tb3V0cHV0LWRpcmVjdG9yeSAiJChwYXRzdWJzdCAkKEJVSUxEX0RJUikvdGVzdC9zcGVjLyUsJChCVUlMRF9ESVIpL3Rlc3Qvc3BlYy1idW5kbGVyLyUsICQoZGlyICQ8KSkiIFwKCQktLW91dHB1dC1wcmVmaXggIiQobm90ZGlyICQocGF0c3Vic3QgJS5sdWEsJSwgJDwpKSIKCWVjaG8gIkNvcHlpbmcgJyQocGF0c3Vic3QgJS5sdWEsJSwgJDwpJyAtPiAnJEAnIgoJbWtkaXIgLXAgIiQoZGlyICRAKSIKCWNwICIkKHBhdHN1YnN0ICQoQlVJTERfRElSKS90ZXN0L3NwZWMvJS5sdWEsJChCVUlMRF9ESVIpL3Rlc3Qvc3BlYy1idW5kbGVyLyUsICQ8KSIgIiRAIgoKCi5QSE9OWTogdGVzdAoKPCUgdGVtcGxhdGU6cG9wKCkgJT4KCmRlcHMvJS9yZXN1bHRzLm1rOiBkZXBzLyUvTWFrZWZpbGUKCUAkKE1BS0UpIC1DICIkKGRpciAkQCkiCgouUEhPTlk6IGFsbCBpbnN0YWxsCg==

LIB_MK_DATA = ZXhwb3J0IFZQRlggPSA8JSByZXR1cm4gdmFyaWFibGVfcHJlZml4ICU+CgppbmNsdWRlICQoYWRkcHJlZml4IC4uLywgJChQQVJFTlRfREVQU19SRVNVTFRTKSkKCkxJQl9MVUEgPSAkKHNoZWxsIGZpbmQgKiAtbmFtZSAnKi5sdWEnKQpMSUJfQyA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmMnKQpMSUJfTyA9ICQoTElCX0M6LmM9Lm8pCkxJQl9TTyA9ICQoTElCX086Lm89LiQoTElCX0VYVEVOU0lPTikpCgpJTlNUX0xVQSA9ICQoYWRkcHJlZml4ICQoSU5TVF9MVUFESVIpLywgJChMSUJfTFVBKSkKSU5TVF9TTyA9ICQoYWRkcHJlZml4ICQoSU5TVF9MSUJESVIpLywgJChMSUJfU08pKQoKTElCX0NGTEFHUyArPSAtV2FsbCAkKGFkZHByZWZpeCAtSSwgJChMVUFfSU5DRElSKSkKTElCX0xERkxBR1MgKz0gLVdhbGwgJChhZGRwcmVmaXggLUwsICQoTFVBX0xJQkRJUikpCgo8JSB0ZW1wbGF0ZTpwdXNoKG9zLmdldGVudigiVEVTVCIpID09ICIxIikgJT4KCmlmZXEgKCQoJChWUEZYKV9TQU5JVElaRSksMSkKTElCX0NGTEFHUyA6PSAtZnNhbml0aXplPWFkZHJlc3MgLWZzYW5pdGl6ZT1sZWFrICQoTElCX0NGTEFHUykKTElCX0xERkxBR1MgOj0gLWZzYW5pdGl6ZT1hZGRyZXNzIC1mc2FuaXRpemU9bGVhayAkKExJQl9MREZMQUdTKQplbmRpZgoKPCUgdGVtcGxhdGU6cG9wKCkgJT4KCmFsbDogJChMSUJfTykgJChMSUJfU08pCgolLm86ICUuYwoJJChDQykgJChMSUJfQ0ZMQUdTKSAkKENGTEFHUykgLWMgLW8gJEAgJDwKCiUuJChMSUJfRVhURU5TSU9OKTogJS5vCgkkKENDKSAkKENGTEFHUykgJChMSUJfTERGTEFHUykgJChMREZMQUdTKSAkKExJQkZMQUcpIC1vICRAICQ8CgppbnN0YWxsOiAkKElOU1RfTFVBKSAkKElOU1RfU08pCgokKElOU1RfTFVBRElSKS8lLmx1YTogLi8lLmx1YQoJbWtkaXIgLXAgJChkaXIgJEApCgljcCAkPCAkQAoKJChJTlNUX0xJQkRJUikvJS4kKExJQl9FWFRFTlNJT04pOiAuLyUuJChMSUJfRVhURU5TSU9OKQoJbWtkaXIgLXAgJChkaXIgJEApCgljcCAkPCAkQAoKLlBIT05ZOiBhbGwgaW5zdGFsbAo=
BIN_MK_DATA = ZXhwb3J0IFZQRlggPSA8JSByZXR1cm4gdmFyaWFibGVfcHJlZml4ICU+CgppbmNsdWRlICQoYWRkcHJlZml4IC4uLywgJChQQVJFTlRfREVQU19SRVNVTFRTKSkKCkJJTl9MVUEgPSAkKHNoZWxsIGZpbmQgKiAtbmFtZSAnKi5sdWEnKQoKSU5TVF9MVUEgPSAkKHBhdHN1YnN0ICUubHVhLCQoSU5TVF9CSU5ESVIpLyUsICQoQklOX0xVQSkpCgphbGw6CglAIyBOb3RoaW5nIHRvIGRvIGhlcmUKCmluc3RhbGw6ICQoSU5TVF9MVUEpCgokKElOU1RfQklORElSKS8lOiAuLyUubHVhCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgouUEhPTlk6IGFsbCBpbnN0YWxsCg==

TEST_LUAROCKS_CFG_DATA = PCUKCnJvY2tzX3Jvb3QgPSBvcy5nZXRlbnYoIlRFU1QiKSA9PSAiMSIKICBhbmQgb3MuZ2V0ZW52KCJCVUlMRF9ESVIiKSAuLiAiL3Rlc3QvbHVhX21vZHVsZXMiCiAgb3Igb3MuZ2V0ZW52KCJCVUlMRF9ESVIiKSAuLiAiL2x1YV9tb2R1bGVzIgoKaXNfd2FzbSA9IG9zLmdldGVudih2YXJpYWJsZV9wcmVmaXggLi4gIl9XQVNNIikgPT0gIjEiCgolPgoKcm9ja3NfdHJlZXMgPSB7CiAgeyBuYW1lID0gInN5c3RlbSIsCiAgICByb290ID0gIjwlIHJldHVybiByb2Nrc19yb290ICU+IgogIH0gfQoKPCUgdGVtcGxhdGU6cHVzaChpc193YXNtKSAlPgoKLS0gTk9URTogTm90IHNwZWNpZnlpbmcgdGhlIGludGVycHJldGVyLCB2ZXJzaW9uLCBMVUEsIExVQV9CSU5ESVIsIGFuZCBMVUFfRElSCi0tIHNvIHRoYXQgdGhlIGhvc3QgbHVhIGlzIHVzZWQgaW5zdGFsbCByb2Nrcy4gVGhlIG90aGVyIHZhcmlhYmxlcyBhZmZlY3QgaG93Ci0tIHRob3NlIHJvY2tzIGFyZSBidWlsdAoKLS0gbHVhX2ludGVycHJldGVyID0gImx1YSIKLS0gbHVhX3ZlcnNpb24gPSAiNS4xIgoKdmFyaWFibGVzID0gewoKICAtLSBMVUEgPSAiPCUgcmV0dXJuIG9zLmdldGVudignQ0xJRU5UX0xVQV9ESVInKSAlPi9iaW4vbHVhIiwKICAtLSBMVUFfQklORElSID0gIjwlIHJldHVybiBvcy5nZXRlbnYoJ0NMSUVOVF9MVUFfRElSJykgJT4vYmluIiwKICAtLSBMVUFfRElSID0gIjwlIHJldHVybiBvcy5nZXRlbnYoJ0NMSUVOVF9MVUFfRElSJykgJT4iLAoKICBMVUFMSUIgPSAibGlibHVhLmEiLAogIExVQV9JTkNESVIgPSAiPCUgcmV0dXJuIG9zLmdldGVudignQ0xJRU5UX0xVQV9ESVInKSAlPi9pbmNsdWRlIiwKICBMVUFfTElCRElSID0gIjwlIHJldHVybiBvcy5nZXRlbnYoJ0NMSUVOVF9MVUFfRElSJykgJT4vbGliIiwKICBMVUFfTElCRElSX0ZJTEUgPSAibGlibHVhLmEiLAoKICBDRkxBR1MgPSAiLUkgPCUgcmV0dXJuIG9zLmdldGVudignQ0xJRU5UX0xVQV9ESVInKSAlPi9pbmNsdWRlIiwKICBMREZMQUdTID0gIi1MIDwlIHJldHVybiBvcy5nZXRlbnYoJ0NMSUVOVF9MVUFfRElSJykgJT4vbGliIiwKICBMSUJGTEFHID0gIi1zaGFyZWQiLAoKICBDQyA9ICJlbWNjIiwKICBDWFggPSAiZW0rKyIsCiAgQVIgPSAiZW1hciIsCiAgTEQgPSAiZW1jYyIsCiAgTk0gPSAibGx2bS1ubSIsCiAgTERTSEFSRUQgPSAiZW1jYyIsCiAgUkFOTElCID0gImVtcmFubGliIiwKCn0KCjwlIHRlbXBsYXRlOnBvcCgpICU+Cg==
TEST_LUACOV_DATA = PCUKCiAgc3RyID0gcmVxdWlyZSgic2FudG9rdS5zdHJpbmciKQogIGZzID0gcmVxdWlyZSgic2FudG9rdS5mcyIpCiAgZ2VuID0gcmVxdWlyZSgic2FudG9rdS5nZW4iKQogIHZlYyA9IHJlcXVpcmUoInNhbnRva3UudmVjdG9yIikKCiAgZmlsZXMgPSBnZW4ucGFjaygibGliIiwgImJpbiIpOmZpbHRlcihmdW5jdGlvbiAoZGlyKQogICAgcmV0dXJuIGNoZWNrKGZzLmV4aXN0cyhkaXIpKQogIGVuZCk6bWFwKGZ1bmN0aW9uIChyZWxkaXIpCiAgICByZWxkaXIgPSByZWxkaXIgLi4gZnMucGF0aGRlbGltCiAgICByZXR1cm4gZnMuZmlsZXMocmVsZGlyLCB7IHJlY3Vyc2UgPSB0cnVlIH0pOm1hcChjaGVjayk6ZmlsdGVyKGZ1bmN0aW9uIChmcCkKICAgICAgcmV0dXJuIHZlYygibHVhIiwgImMiLCAiY3BwIik6aW5jbHVkZXMoc3RyaW5nLmxvd2VyKGZzLmV4dGVuc2lvbihmcCkpKQogICAgZW5kKTpwYXN0ZWwocmVsZGlyKQogIGVuZCk6ZmxhdHRlbigpOm1hcChmdW5jdGlvbiAocmVsZGlyLCBmcCkKICAgIGxvY2FsIG1vZCA9IGZzLnN0cmlwZXh0ZW5zaW9uKHN0ci5zdHJpcHByZWZpeChmcCwgcmVsZGlyKSk6Z3N1YigiLyIsICIuIikKICAgIHJldHVybiBtb2QsIGZwLCBmcy5qb2luKG9zLmdldGVudigiQlVJTERfRElSIiksIGZwKQogIGVuZCkKCiU+Cgptb2R1bGVzID0gewogIDwlIHJldHVybiBmaWxlczptYXAoZnVuY3Rpb24gKG1vZCwgcmVscGF0aCkKICAgIHJldHVybiBzdHIuaW50ZXJwKCJbXCIlbW9kXCJdID0gXCIlcmVscGF0aFwiIiwgeyBtb2QgPSBtb2QsIHJlbHBhdGggPSByZWxwYXRoIH0pCiAgZW5kKTpjb25jYXQoIixcbiIpICU+Cn0KCmluY2x1ZGUgPSB7CiAgPCUgcmV0dXJuIGZpbGVzOm1hcChmdW5jdGlvbiAoXywgXywgZnApCiAgICByZXR1cm4gc3RyLmludGVycCgiXCIlZnBcIiIsIHsgZnAgPSBmcCB9KQogIGVuZCk6Y29uY2F0KCIsXG4iKSAlPgp9CgpzdGF0c2ZpbGUgPSAiPCUgcmV0dXJuIG9zLmdldGVudigiVEVTVF9MVUFDT1ZfU1RBVFNfRklMRSIpICU+IgpyZXBvcnRmaWxlID0gIjwlIHJldHVybiBvcy5nZXRlbnYoIlRFU1RfTFVBQ09WX1JFUE9SVF9GSUxFIikgJT4iCg==
TEST_LUACHECK_DATA = cXVpZXQgPSAxCnN0ZCA9ICJtaW4iCmlnbm9yZSA9IHsgIjQzKiIgfSAtLSBVcHZhbHVlIHNoYWRvd2luZwpnbG9iYWxzID0geyAibmd4IiwgImppdCIgfQo=

export TEST_RUN_SH_DATA = IyEvYmluL3NoCgo8JQogIGdlbiA9IHJlcXVpcmUoInNhbnRva3UuZ2VuIikKICBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpCiAgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKQolPgoKLiAuL2x1YS5lbnYKCjwlIHJldHVybiB2ZWMud3JhcCh0ZXN0X2VudnMgb3Ige30pOmV4dGVuZChzdHIuc3BsaXQob3MuZ2V0ZW52KCJURVNUX0VOVlMiKSBvciAiIikpOmZpbHRlcihmdW5jdGlvbiAoZnApCiAgcmV0dXJuIG5vdCBzdHIuaXNlbXB0eShmcCkKZW5kKTptYXAoZnVuY3Rpb24gKGVudikKICByZXR1cm4gIi4gIiAuLiBlbnYKZW5kKTpjb25jYXQoIlxuIikgJT4KCmlmIFsgLW4gIiRURVNUX0NNRCIgXTsgdGhlbgoKICBzZXQgLXgKICBjZCAiJFJPT1RfRElSIgogICRURVNUX0NNRAoKZWxzZQoKICBybSAtZiBsdWFjb3Yuc3RhdHMub3V0IGx1YWNvdi5yZXBvcnQub3V0IHx8IHRydWUKCiAgPCUgdGVtcGxhdGU6cHVzaChvcy5nZXRlbnYodmFyaWFibGVfcHJlZml4IC4uICJfV0FTTSIpID09ICIxIikgJT4KCiAgICBpZiBbIC1uICIkVEVTVCIgXTsgdGhlbgogICAgICBURVNUPSJzcGVjLWJ1bmRsZWQvJHtURVNUI3Rlc3Qvc3BlYy99IgogICAgICB0b2t1IHRlc3QgLXMgLWkgbm9kZSAiJFRFU1QiCiAgICAgIHN0YXR1cz0kPwogICAgZWxpZiBbIC1kIHNwZWMtYnVuZGxlZCBdOyB0aGVuCiAgICAgIHRva3UgdGVzdCAtcyAtaSBub2RlIHNwZWMtYnVuZGxlZAogICAgICBzdGF0dXM9JD8KICAgIGZpCgogIDwlIHRlbXBsYXRlOnBvcCgpOnB1c2gob3MuZ2V0ZW52KHZhcmlhYmxlX3ByZWZpeCAuLiAiX1dBU00iKSB+PSAiMSIpICU+CgogICAgaWYgWyAtbiAiJFRFU1QiIF07IHRoZW4KICAgICAgVEVTVD0iJHtURVNUI3Rlc3QvfSIKICAgICAgdG9rdSB0ZXN0IC1zIC1pICIkTFVBIC1sIGx1YWNvdiIgIiRURVNUIgogICAgICBzdGF0dXM9JD8KICAgIGVsaWYgWyAtZCBzcGVjIF07IHRoZW4KICAgICAgdG9rdSB0ZXN0IC1zIC1pICIkTFVBIC1sIGx1YWNvdiIgLS1tYXRjaCAiXi4qJS5sdWEkIiBzcGVjCiAgICAgIHN0YXR1cz0kPwogICAgZmkKCiAgPCUgdGVtcGxhdGU6cG9wKCkgJT4KCiAgaWYgWyAiJHN0YXR1cyIgPSAiMCIgXSAmJiBbIC1mIGx1YWNvdi5sdWEgXTsgdGhlbgogICAgbHVhY292IC1jIGx1YWNvdi5sdWEKICBmaQoKICBpZiBbICIkc3RhdHVzIiA9ICIwIiBdICYmIFsgLWYgbHVhY292LnJlcG9ydC5vdXQgXTsgdGhlbgogICAgY2F0IGx1YWNvdi5yZXBvcnQub3V0IHwgYXdrICcvXlN1bW1hcnkvIHsgUCA9IE5SIH0gUCAmJiBOUiA+IFAgKyAxJwogIGZpCgogIGVjaG8KCiAgaWYgWyAtZiBsdWFjaGVjay5sdWEgXTsgdGhlbgogICAgbHVhY2hlY2sgLS1jb25maWcgbHVhY2hlY2subHVhICQoZmluZCBsaWIgYmluIHNwZWMgLW1heGRlcHRoIDAgMj4vZGV2L251bGwpCiAgZmkKCiAgZWNobwoKZmkK

CONFIG_DEPS = $(lastword $(MAKEFILE_LIST))
CONFIG_DEPS += $(ROCKSPEC) $(LUAROCKS_MK) $(LIB_MK) $(BIN_MK)
CONFIG_DEPS += $(TEST_ROCKSPEC) $(TEST_LUAROCKS_MK) $(TEST_LIB_MK) $(TEST_BIN_MK) $(TEST_LUAROCKS_CFG)
CONFIG_DEPS += $(TEST_ENV) $(TEST_LUACOV_CFG) $(TEST_LUACHECK_CFG)
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/, $(LIB) $(BIN) $(RES) $(DEPS))
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/test/, $(LIB) $(BIN) $(RES) $(DEPS))

ifeq ($($(VPFX)_WASM),1)
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/, $(TEST_SPEC) $(TEST_OTHER))
export WASM_TESTS = $(patsubst test/spec/%.lua,$(BUILD_DIR)/test/spec-bundled/%, $(TEST_SPEC))
else
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/, $(TEST_SPEC) $(TEST_OTHER))
endif

TARBALL = $(TARBALL_DIR).tar.gz
TARBALL_DIR = $(NAME)-$(VERSION)
TARBALL_SRCS = Makefile lib/Makefile bin/Makefile $(shell find lib bin deps res -type f 2>/dev/null)

ifeq ($($(VPFX)_WASM),1)
CLIENT_LUA_OK = $(BUILD_DIR)/lua.ok
export CLIENT_LUA_DIR = $(BUILD_DIR)/lua-5.1.5
CONFIG_DEPS := $(CLIENT_LUA_OK) $(CONFIG_DEPS)
$(CLIENT_LUA_OK):
	mkdir -p $(BUILD_DIR)
	[ ! -f $(BUILD_DIR)/lua-5.1.5.tar.gz ] && \
		cd $(BUILD_DIR) && wget https://www.lua.org/ftp/lua-5.1.5.tar.gz || true
	rm -rf $(BUILD_DIR)/lua-5.1.5
	cd $(BUILD_DIR) && tar xf lua-5.1.5.tar.gz
	# TODO: we should  only link nodefs.js and noderawfs.js for the version of lua
	# we're running on the cli, not the version linked to the output programs,
	# right?
	cd $(BUILD_DIR)/lua-5.1.5 && make generic $(CLIENT_VARS) AR="emar rcu" MYLDFLAGS="$(LDFLAGS) -sSINGLE_FILE -sEXIT_RUNTIME=1 -lnodefs.js -lnoderawfs.js"
	cd $(BUILD_DIR)/lua-5.1.5 && make local $(CLIENT_VARS) AR="emar rcu" MYLDFLAGS="$(LDFLAGS) -sSINGLE_FILE -sEXIT_RUNTIME=1 -lnodefs.js -lnoderawfs.js"
	cd $(BUILD_DIR)/lua-5.1.5/bin && mv lua lua.js
	cd $(BUILD_DIR)/lua-5.1.5/bin && mv luac luac.js
	cd $(BUILD_DIR)/lua-5.1.5/bin && printf "#!/bin/sh\nnode \"\$$(dirname \$$0)/lua.js\" \"\$$@\"\n" > lua && chmod +x lua
	cd $(BUILD_DIR)/lua-5.1.5/bin && printf "#!/bin/sh\nnode \"\$$(dirname \$$0)/luac.js\" \"\$$@\"\n" > luac && chmod +x luac
	touch "$@"
endif

all: $(CONFIG_DEPS)
	@echo "Running all"

install: all
	@echo "Running install"
	cd $(BUILD_DIR) && $(LUAROCKS) make $(ROCKSPEC) $(LUAROCKS_VARS)

test: all
	@echo "Running test"
	cd $(BUILD_DIR)/test && $(TEST_LUAROCKS) make $(TEST_ROCKSPEC) $(LUAROCKS_VARS)
	cd $(BUILD_DIR)/test && $(TEST_LUAROCKS) test $(TEST_ROCKSPEC) $(LUAROCKS_VARS)

iterate: all
	@echo "Running iterate"
	@while true; do \
		$(MAKE) test; \
		inotifywait -qqr -e close_write -e create -e delete $(filter-out tmp, $(wildcard *)); \
	done

test-luarocks: $(CONFIG_DEPS)
	$(TEST_LUAROCKS) $(ARGS)

ifeq ($($(VPFX)_PUBLIC),1)

tarball:
	@rm -f $(BUILD_DIR)/$(TARBALL) || true
	cd $(BUILD_DIR) && \
		tar --dereference --transform 's#^#$(TARBALL_DIR)/#' -czvf $(TARBALL) \
			$$(ls $(TARBALL_SRCS) 2>/dev/null)

check-release-status:
	@if test -z "$(LUAROCKS_API_KEY)"; then echo "Missing LUAROCKS_API_KEY variable"; exit 1; fi
	@if ! git diff --quiet; then echo "Commit your changes first"; exit 1; fi

github-release: check-release-status tarball
	gh release create --generate-notes "$(VERSION)" "$(BUILD_DIR)/$(TARBALL)" "$(ROCKSPEC)"

luarocks-upload: check-release-status
	luarocks upload --skip-pack --api-key "$(LUAROCKS_API_KEY)" "$(ROCKSPEC)"

release: test check-release-status
	git tag "$(VERSION)"
	git push --tags
	git push
	$(MAKE) github-release
	$(MAKE) luarocks-upload

endif

$(PREAMBLE): config.lua
	@echo "Generating '$@'"
	@sh -c 'echo $(PREAMBLE_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(ROCKSPEC): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(ROCKSPEC_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LUAROCKS_MK): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(LUAROCKS_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LIB_MK): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(LIB_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(BIN_MK): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(BIN_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(TEST_LIB_MK): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(LIB_MK_DATA) | base64 -d | $(TOKU_TEMPLATE_TEST) -f - -o "$@"'

$(TEST_BIN_MK): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(BIN_MK_DATA) | base64 -d | $(TOKU_TEMPLATE_TEST) -f - -o "$@"'

$(TEST_ROCKSPEC): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(ROCKSPEC_DATA) | base64 -d | $(TOKU_TEMPLATE_TEST) -f - -o "$@"'

$(TEST_LUAROCKS_CFG):
	@echo "Generating '$@'"
	@sh -c 'echo $(TEST_LUAROCKS_CFG_DATA) | base64 -d | $(TOKU_TEMPLATE_TEST) -f - -o "$@"'

$(TEST_LUAROCKS_MK): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(LUAROCKS_MK_DATA) | base64 -d | $(TOKU_TEMPLATE_TEST) -f - -o "$@"'

$(TEST_LUACOV_CFG): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(TEST_LUACOV_DATA) | base64 -d | $(TOKU_TEMPLATE_TEST) -f - -o "$@"'

$(TEST_LUACHECK_CFG): $(PREAMBLE)
	@echo "Generating '$@'"
	@sh -c 'echo $(TEST_LUACHECK_DATA) | base64 -d | $(TOKU_TEMPLATE_TEST) -f - -o "$@"'

$(TEST_ENV): $(PREAMBLE)
	@echo "Generating '$@'"
	@echo "export LUA=\"$(shell $(TEST_LUAROCKS) config lua_interpreter)\"" > "$@"
	@echo "export LUA_PATH=\"$(shell $(TEST_LUAROCKS) path --lr-path);?.lua\"" >> "$@"
	@echo "export LUA_CPATH=\"$(shell $(TEST_LUAROCKS) path --lr-cpath)\"" >> "$@"

$(BUILD_DIR)/%: %
	@case "$<" in \
		res/*) \
			echo "Copying '$<' -> '$@'"; \
			mkdir -p "$(dir $@)"; \
			cp "$<" "$@";; \
		test/res/*) \
			echo "Copying '$<' -> '$@'"; \
			mkdir -p "$(dir $@)"; \
			cp "$<" "$@";; \
		*) \
			echo "Templating '$<' -> '$@'"; \
			$(TOKU_TEMPLATE) -f "$<" -o "$@";; \
	esac

$(BUILD_DIR)/test/%: %
	@case "$<" in \
		res/*) \
			echo "Copying '$<' -> '$@'"; \
			mkdir -p "$(dir $@)"; \
			cp "$<" "$@";; \
		test/res/*) \
			echo "Copying '$<' -> '$@'"; \
			mkdir -p "$(dir $@)"; \
			cp "$<" "$@";; \
		*) \
			echo "Templating '$<' -> '$@'"; \
			$(TOKU_TEMPLATE) -f "$<" -o "$@";; \
	esac

-include $(shell find $(BUILD_DIR) -regex ".*/deps/.*/.*" -prune -o -name "*.d" -print 2>/dev/null)

.PHONY: all test iterate install release check-release-status github-release luarocks-upload test-luarocks
