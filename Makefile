

include .build/preamble.mk

ifndef $(VPFX)_ENV
export $(VPFX)_ENV = default
endif

ROOT_DIR = $(PWD)
BUILD_DIR = $(ROOT_DIR)/.build/$($(VPFX)_ENV)
WEB_DIST_DIR = $(BUILD_DIR)/web-dist

TOKU_TEMPLATE = BUILD_DIR="$(BUILD_DIR)" toku template -M -c config.lua
ROCKSPEC = $(BUILD_DIR)/$(NAME)-$(VERSION).rockspec

WEB = $(WEB_CLIENT) $(WEB_SERVER)
WEB_CLIENT = $(shell find web/client -type f 2>/dev/null)
WEB_SERVER = $(shell find web/server -type f 2>/dev/null)
SRC = $(shell find src -type f 2>/dev/null)
BIN = $(shell find bin -type f 2>/dev/null)
TEST = $(shell find test -type f 2>/dev/null)
RES = $(shell find res -type f 2>/dev/null)
DEPS = $(shell find deps -type f 2>/dev/null)

LUAROCKS = LUAROCKS_CONFIG=$(LUAROCKS_CFG) luarocks
LUAROCKS_MK = $(BUILD_DIR)/Makefile
LUAROCKS_CFG = $(BUILD_DIR)/luarocks.lua

ifneq ($(WEB),)
WEB_MK = $(BUILD_DIR)/web/Makefile
endif

ifneq ($(WEB_CLIENT),)
WEB_CLIENT_MK = $(BUILD_DIR)/web/client/Makefile
endif

ifneq ($(WEB_SERVER),)
WEB_SERVER_MK = $(BUILD_DIR)/web/server/Makefile
WEB_SERVER_NGINX_CFG = $(BUILD_DIR)/web/server/nginx.conf
endif

ifneq ($(SRC),)
SRC_MK = $(BUILD_DIR)/src/Makefile
endif

ifneq ($(BIN),)
BIN_MK = $(BUILD_DIR)/bin/Makefile
endif

ifneq ($(TEST),)
LUACOV_CFG = $(BUILD_DIR)/test/luacov.lua
LUACHECK_CFG = $(BUILD_DIR)/test/luacheck.lua
endif

ifeq ($(shell test -f custom.mk && echo 1),1)
CUSTOM_MK = $(BUILD_DIR)/custom.mk
endif

PREAMBLE_DATA = TkFNRSA9IDwlIHJldHVybiBuYW1lICU+ClZFUlNJT04gPSA8JSByZXR1cm4gdmVyc2lvbiAlPgpWUEZYID0gPCUgcmV0dXJuIHZhcmlhYmxlX3ByZWZpeCAlPgoKZXhwb3J0IExVQSA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQSIpICU+CmV4cG9ydCBMVUFfUEFUSCA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQV9QQVRIIikgJT4KZXhwb3J0IExVQV9DUEFUSCA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQV9DUEFUSCIpICU+CgpleHBvcnQgJChWUEZYKV9QVUJMSUMgPSA8JSByZXR1cm4gcHVibGljIGFuZCAiMSIgb3IgIjAiICU+Cg==
ROCKSPEC_DATA = PCUgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKSAlPgo8JSBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpICU+CgpwYWNrYWdlID0gIjwlIHJldHVybiBuYW1lICU+Igp2ZXJzaW9uID0gIjwlIHJldHVybiB2ZXJzaW9uICU+Igpyb2Nrc3BlY19mb3JtYXQgPSAiMy4wIgoKc291cmNlID0gewogIHVybCA9ICI8JSByZXR1cm4gZG93bmxvYWQgJT4iLAp9CgpkZXNjcmlwdGlvbiA9IHsKICBob21lcGFnZSA9ICI8JSByZXR1cm4gaG9tZXBhZ2UgJT4iLAogIGxpY2Vuc2UgPSAiPCUgcmV0dXJuIGxpY2Vuc2UgJT4iCn0KCmRlcGVuZGVuY2llcyA9IHsKICA8JSByZXR1cm4gdmVjLndyYXAoZGVwZW5kZW5jaWVzIG9yIHt9KTptYXAoc3RyLnF1b3RlKTpjb25jYXQoIixcbiIpICU+Cn0KCnRlc3RfZGVwZW5kZW5jaWVzID0gewogIDwlIHJldHVybiB2ZWMud3JhcCh0ZXN0X2RlcGVuZGVuY2llcyBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9CgpidWlsZCA9IHsKICB0eXBlID0gIm1ha2UiLAogIHZhcmlhYmxlcyA9IHsKICAgIExJQl9FWFRFTlNJT04gPSAiJChMSUJfRVhURU5TSU9OKSIsCiAgfSwKICBidWlsZF92YXJpYWJsZXMgPSB7CiAgICBDQyA9ICIkKENDKSIsCiAgICBDRkxBR1MgPSAiJChDRkxBR1MpIiwKICAgIExJQkZMQUcgPSAiJChMSUJGTEFHKSIsCiAgICBMVUFfQklORElSID0gIiQoTFVBX0JJTkRJUikiLAogICAgTFVBX0lOQ0RJUiA9ICIkKExVQV9JTkNESVIpIiwKICAgIExVQV9MSUJESVIgPSAiJChMVUFfTElCRElSKSIsCiAgICBMVUEgPSAiJChMVUEpIiwKICB9LAogIGluc3RhbGxfdmFyaWFibGVzID0gewogICAgSU5TVF9QUkVGSVggPSAiJChQUkVGSVgpIiwKICAgIElOU1RfQklORElSID0gIiQoQklORElSKSIsCiAgICBJTlNUX0xJQkRJUiA9ICIkKExJQkRJUikiLAogICAgSU5TVF9MVUFESVIgPSAiJChMVUFESVIpIiwKICAgIElOU1RfQ09ORkRJUiA9ICIkKENPTkZESVIpIiwKICB9Cn0KCnRlc3QgPSB7CiAgdHlwZSA9ICJjb21tYW5kIiwKICBjb21tYW5kID0gIm1ha2UgdGVzdCIKfQo=
LUAROCKS_MK_DATA = ZXhwb3J0IFZQRlggPSA8JSByZXR1cm4gdmFyaWFibGVfcHJlZml4ICU+CgpERVBTX0RJUlMgPSAkKHNoZWxsIGZpbmQgZGVwcy8qIC1tYXhkZXB0aCAwIC10eXBlIGQgMj4vZGV2L251bGwpCkRFUFNfUkVTVUxUUyA9ICQoYWRkc3VmZml4IC9yZXN1bHRzLm1rLCAkKERFUFNfRElSUykpCgppbmNsdWRlICQoREVQU19SRVNVTFRTKQoKYWxsOiAkKERFUFNfUkVTVUxUUykgbHVhLmVudgoJQGlmIFsgLWQgc3JjIF07IHRoZW4gJChNQUtFKSAtRSAiaW5jbHVkZSAkKGFkZHByZWZpeCAuLi8sICQoREVQU19SRVNVTFRTKSkiIC1DIHNyYzsgZmkKCUBpZiBbIC1kIGJpbiBdOyB0aGVuICQoTUFLRSkgLUUgImluY2x1ZGUgJChhZGRwcmVmaXggLi4vLCAkKERFUFNfUkVTVUxUUykpIiAtQyBiaW47IGZpCglAaWYgWyAtZCB3ZWIgXTsgdGhlbiAkKE1BS0UpIC1FICJpbmNsdWRlICQoYWRkcHJlZml4IC4uLywgJChERVBTX1JFU1VMVFMpKSIgLUMgd2ViOyBmaQoKaW5zdGFsbDogYWxsCglAaWYgWyAtZCBzcmMgXTsgdGhlbiAkKE1BS0UpIC1DIHNyYyBpbnN0YWxsOyBmaQoJQGlmIFsgLWQgYmluIF07IHRoZW4gJChNQUtFKSAtQyBiaW4gaW5zdGFsbDsgZmkKCmlmZXEgKCQoc2hlbGwgdGVzdCAtZCB0ZXN0ICYmIGVjaG8gMSksMSkKCnRlc3Q6CglAcm0gLWYgbHVhY292LnN0YXRzLm91dCBsdWFjb3Yuc3RhdHMub3V0IHx8IHRydWUKCUAuIC4vbHVhLmVudiAmJiAkKCQoVlBGWClfVEVTVF9QUkVGSVgpIFwKCQl0b2t1IHRlc3QgLWkgIiQoTFVBKSAtbCBsdWFjb3YiIC0tbWF0Y2ggIl4uKiUubHVhJCQiIHRlc3Qvc3BlYwoJQGx1YWNvdiAtYyB0ZXN0L2x1YWNvdi5sdWEgfHwgdHJ1ZQoJQGNhdCBsdWFjb3YucmVwb3J0Lm91dCB8IGF3ayAnL15TdW1tYXJ5LyB7IFAgPSBOUiB9IFAgJiYgTlIgPiBQICsgMScKCUBlY2hvCglAbHVhY2hlY2sgLS1jb25maWcgdGVzdC9sdWFjaGVjay5sdWEgc3JjIGJpbiB0ZXN0L3NwZWMgfHwgdHJ1ZQoJQGVjaG8KCmVsc2UKCnRlc3Q6CgplbmRpZgoKbHVhLmVudjoKCUBlY2hvIGV4cG9ydCBMVUE9IiQoTFVBKSIgPiBsdWEuZW52CgpkZXBzLyUvcmVzdWx0cy5tazogZGVwcy8lL01ha2VmaWxlCglAJChNQUtFKSAtQyAiJChkaXIgJEApIgoKLlBIT05ZOiBhbGwgdGVzdCBpbnN0YWxsCg==
LUAROCKS_CFG_DATA = cm9ja3NfdHJlZXMgPSB7CiAgeyBuYW1lID0gInN5c3RlbSIsCiAgICByb290ID0gIjwlIHJldHVybiBvcy5nZXRlbnYoJ0JVSUxEX0RJUicpICU+L2x1YV9tb2R1bGVzIgogIH0gfQo=
WEB_MK_DATA = YWxsOgoJQGlmIFsgLWQgc2VydmVyIF07IHRoZW4gJChNQUtFKSAtQyBzZXJ2ZXI7IGZpCglAaWYgWyAtZCBjbGllbnQgXTsgdGhlbiAkKE1BS0UpIC1DIGNsaWVudDsgZmkKCi5QSE9OWTogYWxsCg==
WEB_CLIENT_MK_DATA = IyBUb3AtbGV2ZWw6CiMgICAtIFJlbmRlciBjbGllbnQgcm9ja3NwZWMKIyAgIC0gUmVuZGVyIHNlcnZlciBydW4uc2gKCiMgQ2xpZW50LWxldmVsOgojIAktIE5vdGU6IHVzZSBjb25maWcubHVhL2V0YyBzcGVjaWZ5aW5nIGVtY2MgbHVhX2RpciwgZXRjLiAobGF0ZXIpCiMgCS0gQnVpbGQgbHVhIGZvciBlbXNjcmlwdGVuIChsYXRlcikKIyAJLSBCdW5kbGUgcGFnZXMvKiB0byB3ZWItZGlzdC9wdWJsaWMvKgojICAgCS0gTFVBX1BBVEgvQ1BBVEggc2V0IHRvIGx1YV9tb2R1bGVzX2NsaWVudCwgbHVhX21vZHVsZXNfc2hhcmVkCiMgCS0gSW5zdGFsbCBzaGFyZWQgcm9ja3NwZWMgdG8gLi9sdWFfbW9kdWxlc19zaGFyZWQgKGxhdGVyKQojIAktIEluc3RhbGwgY2xpZW50IHJvY2tzcGVjIHRvIC4vbHVhX21vZHVsZXNfY2xpZW50IChsYXRlcikKIyAJLSBDb3B5IHJlcy8qIHRvIHdlYi1kaXN0L3B1YmxpYy8qCiMgCS0gQ29weSBzdGF0aWMvKiB0byB3ZWItZGlzdC9wdWJsaWMvKgoKYWxsOgoKLlBIT05ZOiBhbGwK
WEB_SERVER_MK_DATA = IyBUb3AtbGV2ZWw6CiMgICAtIFJlbmRlciBzZXJ2ZXIgcm9ja3NwZWMKIyAgIC0gUmVuZGVyIHNlcnZlciBydW4uc2gKIyAgIAktIExVQV9QQVRIL0NQQVRIIHNldCB0byBtb2R1bGVzLCBsdWFfbW9kdWxlc19zZXJ2ZXIsIGx1YV9tb2R1bGVzX3NoYXJlZAoKIyBTZXJ2ZXItbGV2ZWw6CiMgCS0gTm90ZTogdXNlIGNvbmZpZy5sdWEgc3BlY2lmeWluZyBvcGVucmVzdHkgbHVhaml0IGx1YV9kaXIsIGV0Yy4KIyAJLSBTb3VyY2Ugc2hhcmVkIGRlcHMgKGxhdGVyKQojIAktIEJ1aWxkICYgc291cmNlIHNlcnZlciBkZXBzIChsYXRlcikKIyAJLSBJbnN0YWxsIHNoYXJlZCByb2Nrc3BlYyB0byB3ZWItZGlzdC9sdWFfbW9kdWxlc19zaGFyZWQKIyAJLSBJbnN0YWxsIHNlcnZlciByb2Nrc3BlYyB0byB3ZWItZGlzdC9sdWFfbW9kdWxlc19zZXJ2ZXIKIyAJLSBDb3B5IHNjcmlwdHMvKiB0byB3ZWItZGlzdC9zY3JpcHRzLyoKIyAJLSBDb3B5IG5naW54LmNvbmYgdG8gd2ViLWRpc3QvbmdpbnguY29uZgoKYWxsOgoKLlBIT05ZOiBhbGwK
WEB_SERVER_NGINX_CFG_DATA = PCUgZ2VuID0gcmVxdWlyZSgic2FudG9rdS5nZW4iKSAlPgo8JSBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpICU+CjwlIHNlcnZlciA9ICh3ZWIgb3Ige30pLnNlcnZlciBvciB7fSAlPgoKcGlkIHNlcnZlci5waWQ7Cndvcmtlcl9wcm9jZXNzZXMgYXV0bzsKCmV2ZW50cyB7fQoKaHR0cCB7CgogIGluY2x1ZGUgL2V0Yy9uZ2lueC9taW1lLnR5cGVzOwoKICBhY2Nlc3NfbG9nIGFjY2Vzcy5sb2c7CgogIDwlIHRlbXBsYXRlOnB1c2goc2VydmVyLmluaXQpICU+CiAgaW5pdF9ieV9sdWFfZmlsZSBtb2R1bGVzLzwlIHJldHVybiBzZXJ2ZXIuaW5pdCAlPjsKICA8JSB0ZW1wbGF0ZTpwb3AoKSAlPgoKICA8JSB0ZW1wbGF0ZTpwdXNoKHNlcnZlci5pbml0X3dvcmtlcikgJT4KICBpbml0X3dvcmtlcl9ieV9sdWFfZmlsZSBtb2R1bGVzLzwlIHJldHVybiBzZXJ2ZXIuaW5pdF93b3JrZXIgJT47CiAgPCUgdGVtcGxhdGU6cG9wKCkgJT4KCiAgdHlwZXNfaGFzaF9tYXhfc2l6ZSA8JSByZXR1cm4gc2VydmVyLnR5cGVzX2hhc2hfbWF4X3NpemUgb3IgIjIwNDgiICU+OwogIHR5cGVzX2hhc2hfYnVja2V0X3NpemUgPCUgcmV0dXJuIHNlcnZlci50eXBlc19oYXNoX21heF9zaXplIG9yICIxMjgiICU+OwoKICA8JSB0ZW1wbGF0ZTpwdXNoKHNlcnZlci5zc2wpICU+CgogIHNzbF9jZXJ0aWZpY2F0ZSA8JSByZXR1cm4gc2VydmVyLnNzbF9jZXJ0aWZpY2F0ZSAlPjsKICBzc2xfY2VydGlmaWNhdGVfa2V5IDwlIHJldHVybiBzZXJ2ZXIuc3NsX2NlcnRpZmljYXRlX2tleSAlPjsKCiAgc2VydmVyIHsKICAgIHNlcnZlcl9uYW1lIF87CiAgICBsaXN0ZW4gPCUgcmV0dXJuIHNlcnZlci5zZXJ2ZXJfcG9ydCAlPjsKICAgIGxpc3RlbiBbOjpdOjwlIHJldHVybiBzZXJ2ZXIuc2VydmVyX3BvcnQgJT47CiAgICByZXR1cm4gMzAxIGh0dHBzOi8vJGhvc3QkcmVxdWVzdF91cmk7CiAgfQoKICA8JSB0ZW1wbGF0ZTpwb3AoKTpwdXNoKHNlcnZlci5yZWRpcmVjdF9iYXNlX2RvbWFpbikgJT4KCiAgc2VydmVyIHsKICAgIHNlcnZlcl9uYW1lIDwlIHJldHVybiBzZXJ2ZXIuZG9tYWluX2Jhc2UgJT47CiAgICBsaXN0ZW4gPCUgcmV0dXJuIHNlcnZlci5zZXJ2ZXJfcG9ydF9zc2wgJT4gc3NsOwogICAgbGlzdGVuIFs6Ol06PCUgcmV0dXJuIHNlcnZlci5zZXJ2ZXJfcG9ydF9zc2wgJT4gc3NsOwogICAgcmV0dXJuIDMwMSBodHRwczovLzwlIHJldHVybiBzZXJ2ZXIuZG9tYWluICU+JHJlcXVlc3RfdXJpOwogIH0KCiAgPCUgdGVtcGxhdGU6cG9wKCkgJT4KCiAgc2VydmVyIHsKCiAgICBzZXJ2ZXJfbmFtZSA8JSByZXR1cm4gc2VydmVyLmRvbWFpbiAlPjsKCiAgICA8JSB0ZW1wbGF0ZTpwdXNoKHNlcnZlci5zc2wpICU+CiAgICBsaXN0ZW4gPCUgcmV0dXJuIHNlcnZlci5zZXJ2ZXJfcG9ydF9zc2wgJT4gc3NsOwogICAgbGlzdGVuIFs6Ol06PCUgcmV0dXJuIHNlcnZlci5zZXJ2ZXJfcG9ydF9zc2wgJT4gc3NsOwogICAgPCUgdGVtcGxhdGU6cG9wKCk6cHVzaChub3Qgc2VydmVyLnNzbCkgJT4KICAgIGxpc3RlbiA8JSByZXR1cm4gc2VydmVyLnNlcnZlcl9wb3J0ICU+OwogICAgbGlzdGVuIFs6Ol06PCUgcmV0dXJuIHNlcnZlci5zZXJ2ZXJfcG9ydCAlPjsKICAgIDwlIHRlbXBsYXRlOnBvcCgpICU+CgogICAgbG9jYXRpb24gLyB7CiAgICAgIGxpbWl0X2V4Y2VwdCBHRVQgeyBkZW55IGFsbDsgfQogICAgICByb290IHB1YmxpYzsKICAgICAgYWRkX2hlYWRlciBDcm9zcy1PcmlnaW4tRW1iZWRkZXItUG9saWN5IHJlcXVpcmUtY29ycDsKICAgICAgYWRkX2hlYWRlciBDcm9zcy1PcmlnaW4tT3BlbmVyLVBvbGljeSBzYW1lLW9yaWdpbjsKICAgICAgdHJ5X2ZpbGVzICR1cmkgJHVyaS5odG1sICR1cmkvaW5kZXguaHRtbCA9NDA0OwogICAgfQoKICAgIDwlIHJldHVybiBnZW4uaXZhbHMoc2VydmVyLnJvdXRlcyBvciB7fSk6bWFwKGZ1bmN0aW9uIChyb3V0ZSkKICAgICAgcmV0dXJuIHN0ci5pbnRlcnAoW1sKICAgICAgICBsb2NhdGlvbiA9ICUyIHsKICAgICAgICAgIGxpbWl0X2V4Y2VwdCAlMSB7IGRlbnkgYWxsOyB9CiAgICAgICAgICBjb250ZW50X2J5X2x1YV9maWxlIG1vZHVsZXMvJTM7CiAgICAgICAgfQogICAgICBdXSwgcm91dGUpCiAgICBlbmQpOmNvbmNhdCgiXG5cbiIpICU+CgogIH0KCn0K
SRC_MK_DATA = U1JDX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpClNSQ19DID0gJChzaGVsbCBmaW5kICogLW5hbWUgJyouYycpClNSQ19PID0gJChTUkNfQzouYz0ubykKU1JDX1NPID0gJChTUkNfTzoubz0uJChMSUJfRVhURU5TSU9OKSkKCklOU1RfTFVBID0gJChhZGRwcmVmaXggJChJTlNUX0xVQURJUikvLCAkKFNSQ19MVUEpKQpJTlNUX1NPID0gJChhZGRwcmVmaXggJChJTlNUX0xJQkRJUikvLCAkKFNSQ19TTykpCgpMSUJfQ0ZMQUdTICs9IC1XYWxsIC1JJChMVUFfSU5DRElSKQpMSUJfTERGTEFHUyArPSAtV2FsbCAtTCQoTFVBX0xJQkRJUikKCmlmZXEgKCQoJChWUEZYKV9TQU5JVElaRSksMSkKTElCX0NGTEFHUyArPSAtZnNhbml0aXplPWFkZHJlc3MgLWZzYW5pdGl6ZT1sZWFrCkxJQl9MREZMQUdTICs9IC1mc2FuaXRpemU9YWRkcmVzcyAtZnNhbml0aXplPWxlYWsKZW5kaWYKCmFsbDogJChTUkNfTykgJChTUkNfU08pCgolLm86ICUuYwoJJChDQykgJChMSUJfQ0ZMQUdTKSAkKENGTEFHUykgLWMgLW8gJEAgJDwKCiUuJChMSUJfRVhURU5TSU9OKTogJS5vCgkkKENDKSAkKExJQl9MREZMQUdTKSAkKExERkxBR1MpICQoTElCRkxBRykgLW8gJEAgJDwKCmluc3RhbGw6ICQoSU5TVF9MVUEpICQoSU5TVF9TTykKCiQoSU5TVF9MVUFESVIpLyUubHVhOiAuLyUubHVhCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgokKElOU1RfTElCRElSKS8lLiQoTElCX0VYVEVOU0lPTik6IC4vJS4kKExJQl9FWFRFTlNJT04pCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgouUEhPTlk6IGFsbCBpbnN0YWxsCg==
BIN_MK_DATA = QklOX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpCgpJTlNUX0xVQSA9ICQocGF0c3Vic3QgJS5sdWEsJChJTlNUX0JJTkRJUikvJSwgJChCSU5fTFVBKSkKCmFsbDoKCUAjIE5vdGhpbmcgdG8gZG8gaGVyZQoKaW5zdGFsbDogJChJTlNUX0xVQSkKCiQoSU5TVF9CSU5ESVIpLyU6IC4vJS5sdWEKCW1rZGlyIC1wICQoZGlyICRAKQoJY3AgJDwgJEAKCi5QSE9OWTogYWxsIGluc3RhbGwK
LUACOV_DATA = PCUgc3RyID0gcmVxdWlyZSgic2FudG9rdS5zdHJpbmciKSAlPgo8JSBmcyA9IHJlcXVpcmUoInNhbnRva3UuZnMiKSAlPgo8JSBnZW4gPSByZXF1aXJlKCJzYW50b2t1LmdlbiIpICU+CjwlIHZlYyA9IHJlcXVpcmUoInNhbnRva3UudmVjdG9yIikgJT4KCjwlIGZpbGVzID0gZ2VuLnBhY2soInNyYyIsICJiaW4iKTpmaWx0ZXIoZnVuY3Rpb24gKGRpcikKICByZXR1cm4gY2hlY2soZnMuZXhpc3RzKGRpcikpCmVuZCk6bWFwKGZ1bmN0aW9uIChyZWxkaXIpCiAgcmVsZGlyID0gcmVsZGlyIC4uIGZzLnBhdGhkZWxpbQogIHJldHVybiBmcy5maWxlcyhyZWxkaXIsIHsgcmVjdXJzZSA9IHRydWUgfSk6bWFwKGNoZWNrKTpmaWx0ZXIoZnVuY3Rpb24gKGZwKQogICAgcmV0dXJuIHZlYygibHVhIiwgImMiLCAiY3BwIik6aW5jbHVkZXMoc3RyaW5nLmxvd2VyKGZzLmV4dGVuc2lvbihmcCkpKQogIGVuZCk6cGFzdGVsKHJlbGRpcikKZW5kKTpmbGF0dGVuKCk6bWFwKGZ1bmN0aW9uIChyZWxkaXIsIGZwKQogIGxvY2FsIG1vZCA9IGZzLnN0cmlwZXh0ZW5zaW9uKHN0ci5zdHJpcHByZWZpeChmcCwgcmVsZGlyKSk6Z3N1YigiLyIsICIuIikKICByZXR1cm4gbW9kLCBmcCwgZnMuam9pbihvcy5nZXRlbnYoIkJVSUxEX0RJUiIpLCBmcCkKZW5kKSAlPgoKbW9kdWxlcyA9IHsKICA8JSByZXR1cm4gZmlsZXM6bWFwKGZ1bmN0aW9uIChtb2QsIHJlbHBhdGgpCiAgICByZXR1cm4gc3RyLmludGVycCgiW1wiJW1vZFwiXSA9IFwiJXJlbHBhdGhcIiIsIHsgbW9kID0gbW9kLCByZWxwYXRoID0gcmVscGF0aCB9KQogIGVuZCk6Y29uY2F0KCIsXG4iKSAlPgp9CgppbmNsdWRlID0gewogIDwlIHJldHVybiBmaWxlczptYXAoZnVuY3Rpb24gKF8sIF8sIGZwKQogICAgcmV0dXJuIHN0ci5pbnRlcnAoIlwiJWZwXCIiLCB7IGZwID0gZnAgfSkKICBlbmQpOmNvbmNhdCgiLFxuIikgJT4KfQo=
LUACHECK_DATA = cXVpZXQgPSAxCnN0ZCA9ICJtaW4iCmlnbm9yZSA9IHsgIjQzKiIgfSAtLSBVcHZhbHVlIHNoYWRvd2luZwpnbG9iYWxzID0geyAibmd4IiwgImppdCIgfQo=

CONFIG_DEPS = $(lastword $(MAKEFILE_LIST))
CONFIG_DEPS += $(ROCKSPEC) $(LUAROCKS_MK) $(LUAROCKS_CFG) $(WEB_MK) $(WEB_CLIENT_MK) $(WEB_SERVER_MK) $(WEB_SERVER_NGINX_CFG) $(SRC_MK) $(BIN_MK) $(LUACOV_CFG) $(LUACHECK_CFG) $(CUSTOM_MK)
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/, $(WEB) $(SRC) $(BIN) $(TEST) $(RES) $(DEPS))

TARBALL = $(TARBALL_DIR).tar.gz
TARBALL_DIR = $(NAME)-$(VERSION)

# TODO: Should this include web and res?
TARBALL_SRCS = Makefile src/Makefile bin/Makefile $(shell find src bin deps -type f 2>/dev/null)

all: $(CONFIG_DEPS)
	@echo "Running all"
	@cd $(BUILD_DIR) && $(LUAROCKS) make $(ROCKSPEC)

test: all
	@echo "Running test"
	@cd $(BUILD_DIR) && $(LUAROCKS) test $(ROCKSPEC)

iterate:
	@echo "Running iterate"
	@while true; do \
		$(MAKE) test; \
		inotifywait -qqr -e close_write -e create -e delete *; \
	done

# NOTE: intentionally not using $(LUAROCKS) here
install: all
	@cd $(BUILD_DIR) && luarocks make $(ROCKSPEC)

touch:
	@find * -exec touch {} \+

clean:
	@echo "Cleaning all but deps"
	@find $(BUILD_DIR)/* -maxdepth 1 -name deps -prune -o -print | xargs rm -rf

clean-deps:
	@echo "Cleaning .d files"
	@find $(BUILD_DIR) -regex ".*/deps/.*/.*" -prune -o -name "*.d" -print 2>/dev/null | xargs rm -f

clean-all:
	@echo "Cleaning all"
	@rm -rf "$(BUILD_DIR)"

ifeq ($($(VPFX)_PUBLIC),1)

tarball:
	@rm -f $(BUILD_DIR)/$(TARBALL) || true
	@cd $(BUILD_DIR) && \
		tar --dereference --transform 's#^#$(TARBALL_DIR)/#' -czvf $(TARBALL) \
			$$(ls $(TARBALL_SRCS) 2>/dev/null)

check-release-status:
	@if test -z "$(LUAROCKS_API_KEY)"; then echo "Missing LUAROCKS_API_KEY variable"; exit 1; fi
	@if ! git diff --quiet; then echo "Commit your changes first"; exit 1; fi

github-release: check-release-status tarball
	@gh release create --generate-notes "$(VERSION)" "$(BUILD_DIR)/$(TARBALL)" "$(ROCKSPEC)"

luarocks-upload: check-release-status
	@luarocks upload --skip-pack --api-key "$(LUAROCKS_API_KEY)" "$(ROCKSPEC)"

release: check-release-status all
	@git tag "$(VERSION)"
	@git push --tags
	@git push
	@$(MAKE) github-release
	@$(MAKE) luarocks-upload

endif

.build/preamble.mk: config.lua
	@echo "Generating '$@'"
	@LUA="$(shell $(LUAROCKS) config lua_interpreter)" \
	LUA_PATH="$(shell $(LUAROCKS) path --lr-path);?.lua" \
	LUA_CPATH="$(shell $(LUAROCKS) path --lr-cpath)" \
		sh -c 'echo $(PREAMBLE_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(ROCKSPEC): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(ROCKSPEC_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LUAROCKS_MK): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(LUAROCKS_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LUAROCKS_CFG): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(LUAROCKS_CFG_DATA) | base64 -d | BUILD_DIR="$(BUILD_DIR)" $(TOKU_TEMPLATE) -f - -o "$@"'

$(WEB_MK): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(WEB_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(WEB_CLIENT_MK): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(WEB_CLIENT_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(WEB_SERVER_MK): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(WEB_SERVER_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(WEB_SERVER_NGINX_CFG): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(WEB_SERVER_NGINX_CFG_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(SRC_MK): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(SRC_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(BIN_MK): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(BIN_MK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LUACOV_CFG): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(LUACOV_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

$(LUACHECK_CFG): .build/preamble.mk
	@echo "Generating '$@'"
	@sh -c 'echo $(LUACHECK_DATA) | base64 -d | $(TOKU_TEMPLATE) -f - -o "$@"'

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
		web/client/res/*) \
			echo "Copying '$<' -> '$@'"; \
			mkdir -p "$(dir $@)"; \
			cp "$<" "$@";; \
		*) \
			echo "Templating '$<' -> '$@'"; \
			$(TOKU_TEMPLATE) -f "$<" -o "$@";; \
	esac

-include $(shell find $(BUILD_DIR) -regex ".*/deps/.*/.*" -prune -o -name "*.d" -print 2>/dev/null)

.PHONY: all test iterate install touch clean clean-all release check-release-status github-release luarocks-upload
.DEFAULT_GOAL: all
