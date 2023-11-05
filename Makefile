

all:

-include config.mk

export ROOT_DIR = $(PWD)
export BUILD_BASE_DIR = $(ROOT_DIR)/.build
export PREAMBLE = $(BUILD_BASE_DIR)/preamble.mk

include $(PREAMBLE)

ifndef $(VPFX)_ENV
export $(VPFX)_ENV = default
endif

export BUILD_DIR = $(BUILD_BASE_DIR)/$($(VPFX)_ENV)

TOKU_TEMPLATE = BUILD_DIR="$(BUILD_DIR)" toku template -M -c $(ROOT_DIR)/config.lua
export TOKU_TEMPLATE_TEST = TEST=1 $(TOKU_TEMPLATE)
ROCKSPEC = $(BUILD_DIR)/$(NAME)-$(VERSION).rockspec

LIB = $(shell find lib -type f 2>/dev/null)
BIN = $(shell find bin -type f 2>/dev/null)
TEST = $(shell find test -type f 2>/dev/null)
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
TEST_LUAROCKS = LUAROCKS_CONFIG=$(TEST_LUAROCKS_CFG) luarocks
TEST_LUAROCKS_CFG = $(BUILD_DIR)/test/luarocks.lua
TEST_LUAROCKS_MK = $(BUILD_DIR)/test/Makefile
TEST_ENV = $(BUILD_DIR)/test/lua.env
TEST_LUACOV_CFG = $(BUILD_DIR)/test/luacov.lua
TEST_LUACHECK_CFG = $(BUILD_DIR)/test/luacheck.lua

PREAMBLE_DATA = TkFNRSA9IDwlIHJldHVybiBuYW1lICU+ClZFUlNJT04gPSA8JSByZXR1cm4gdmVyc2lvbiAlPgpWUEZYID0gPCUgcmV0dXJuIHZhcmlhYmxlX3ByZWZpeCAlPgoKZXhwb3J0ICQoVlBGWClfUFVCTElDID0gPCUgcmV0dXJuIHB1YmxpYyBhbmQgIjEiIG9yICIwIiAlPgo=
ROCKSPEC_DATA = PCUgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKSAlPgo8JSBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpICU+CgpwYWNrYWdlID0gIjwlIHJldHVybiBuYW1lICU+Igp2ZXJzaW9uID0gIjwlIHJldHVybiB2ZXJzaW9uICU+Igpyb2Nrc3BlY19mb3JtYXQgPSAiMy4wIgoKc291cmNlID0gewogIHVybCA9ICI8JSByZXR1cm4gZG93bmxvYWQgJT4iLAp9CgpkZXNjcmlwdGlvbiA9IHsKICBob21lcGFnZSA9ICI8JSByZXR1cm4gaG9tZXBhZ2UgJT4iLAogIGxpY2Vuc2UgPSAiPCUgcmV0dXJuIGxpY2Vuc2Ugb3IgJ1VOTElDRU5TRUQnICU+Igp9CgpkZXBlbmRlbmNpZXMgPSB7CiAgPCUgcmV0dXJuIHZlYy53cmFwKGRlcGVuZGVuY2llcyBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9CgpidWlsZCA9IHsKICB0eXBlID0gIm1ha2UiLAogIG1ha2VmaWxlID0gIk1ha2VmaWxlIiwKICB2YXJpYWJsZXMgPSB7CiAgICBMSUJfRVhURU5TSU9OID0gIiQoTElCX0VYVEVOU0lPTikiLAogIH0sCiAgYnVpbGRfdmFyaWFibGVzID0gewogICAgQ0MgPSAiJChDQykiLAogICAgQ0ZMQUdTID0gIiQoQ0ZMQUdTKSIsCiAgICBMSUJGTEFHID0gIiQoTElCRkxBRykiLAogICAgTFVBX0JJTkRJUiA9ICIkKExVQV9CSU5ESVIpIiwKICAgIExVQV9JTkNESVIgPSAiJChMVUFfSU5DRElSKSIsCiAgICBMVUFfTElCRElSID0gIiQoTFVBX0xJQkRJUikiLAogICAgTFVBID0gIiQoTFVBKSIsCiAgfSwKICBpbnN0YWxsX3ZhcmlhYmxlcyA9IHsKICAgIElOU1RfUFJFRklYID0gIiQoUFJFRklYKSIsCiAgICBJTlNUX0JJTkRJUiA9ICIkKEJJTkRJUikiLAogICAgSU5TVF9MSUJESVIgPSAiJChMSUJESVIpIiwKICAgIElOU1RfTFVBRElSID0gIiQoTFVBRElSKSIsCiAgICBJTlNUX0NPTkZESVIgPSAiJChDT05GRElSKSIsCiAgfQp9Cgo8JSB0ZW1wbGF0ZTpwdXNoKG9zLmdldGVudigiVEVTVCIpID09ICIxIikgJT4KCnRlc3RfZGVwZW5kZW5jaWVzID0gewogIDwlIHJldHVybiB2ZWMud3JhcCh0ZXN0X2RlcGVuZGVuY2llcyBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9Cgp0ZXN0ID0gewogIHR5cGUgPSAiY29tbWFuZCIsCiAgY29tbWFuZCA9ICJtYWtlIHRlc3QiCn0KCjwlIHRlbXBsYXRlOnBvcCgpICU+Cg==

LUAROCKS_MK_DATA = ZXhwb3J0IFZQRlggPSA8JSByZXR1cm4gdmFyaWFibGVfcHJlZml4ICU+CgpERVBTX0RJUlMgPSAkKHNoZWxsIGZpbmQgZGVwcy8qIC1tYXhkZXB0aCAwIC10eXBlIGQgMj4vZGV2L251bGwpCkRFUFNfUkVTVUxUUyA9ICQoYWRkc3VmZml4IC9yZXN1bHRzLm1rLCAkKERFUFNfRElSUykpCgppbmNsdWRlICQoREVQU19SRVNVTFRTKQoKYWxsOiAkKERFUFNfUkVTVUxUUykgJChURVNUX1JVTl9TSCkKCUBpZiBbIC1kIGxpYiBdOyB0aGVuICQoTUFLRSkgLUUgImluY2x1ZGUgJChhZGRwcmVmaXggLi4vLCAkKERFUFNfUkVTVUxUUykpIiAtQyBsaWI7IGZpCglAaWYgWyAtZCBiaW4gXTsgdGhlbiAkKE1BS0UpIC1FICJpbmNsdWRlICQoYWRkcHJlZml4IC4uLywgJChERVBTX1JFU1VMVFMpKSIgLUMgYmluOyBmaQoKaW5zdGFsbDogYWxsCglAaWYgWyAtZCBsaWIgXTsgdGhlbiAkKE1BS0UpIC1DIGxpYiBpbnN0YWxsOyBmaQoJQGlmIFsgLWQgYmluIF07IHRoZW4gJChNQUtFKSAtQyBiaW4gaW5zdGFsbDsgZmkKCjwlIHRlbXBsYXRlOnB1c2gob3MuZ2V0ZW52KCJURVNUIikgPT0gIjEiKSAlPgoKVEVTVF9SVU5fU0ggPSBydW4uc2gKCnRlc3Q6ICQoVEVTVF9SVU5fU0gpCglzaCAkKFRFU1RfUlVOX1NIKQoKJChURVNUX1JVTl9TSCk6ICQoUFJFQU1CTEUpCglAZWNobyAiR2VuZXJhdGluZyAnJEAnIgoJQHNoIC1jICdlY2hvICQoVEVTVF9SVU5fU0hfREFUQSkgfCBiYXNlNjQgLWQgfCAkKFRPS1VfVEVNUExBVEVfVEVTVCkgLWYgLSAtbyAiJEAiJwoKLlBIT05ZOiB0ZXN0Cgo8JSB0ZW1wbGF0ZTpwb3AoKSAlPgoKZGVwcy8lL3Jlc3VsdHMubWs6IGRlcHMvJS9NYWtlZmlsZQoJQCQoTUFLRSkgLUMgIiQoZGlyICRAKSIKCi5QSE9OWTogYWxsIGluc3RhbGwK

LIB_MK_DATA = TElCX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpCkxJQl9DID0gJChzaGVsbCBmaW5kICogLW5hbWUgJyouYycpCkxJQl9PID0gJChMSUJfQzouYz0ubykKTElCX1NPID0gJChMSUJfTzoubz0uJChMSUJfRVhURU5TSU9OKSkKCklOU1RfTFVBID0gJChhZGRwcmVmaXggJChJTlNUX0xVQURJUikvLCAkKExJQl9MVUEpKQpJTlNUX1NPID0gJChhZGRwcmVmaXggJChJTlNUX0xJQkRJUikvLCAkKExJQl9TTykpCgpMSUJfQ0ZMQUdTICs9IC1XYWxsIC1JJChMVUFfSU5DRElSKQpMSUJfTERGTEFHUyArPSAtV2FsbCAtTCQoTFVBX0xJQkRJUikKCjwlIHRlbXBsYXRlOnB1c2gob3MuZ2V0ZW52KCJURVNUIikgPT0gIjEiKSAlPgoKaWZlcSAoJCgkKFZQRlgpX1NBTklUSVpFKSwxKQpMSUJfQ0ZMQUdTICs9IC1mc2FuaXRpemU9YWRkcmVzcyAtZnNhbml0aXplPWxlYWsKTElCX0xERkxBR1MgKz0gLWZzYW5pdGl6ZT1hZGRyZXNzIC1mc2FuaXRpemU9bGVhawplbmRpZgoKPCUgdGVtcGxhdGU6cG9wKCkgJT4KCmFsbDogJChMSUJfTykgJChMSUJfU08pCgolLm86ICUuYwoJJChDQykgJChMSUJfQ0ZMQUdTKSAkKENGTEFHUykgLWMgLW8gJEAgJDwKCiUuJChMSUJfRVhURU5TSU9OKTogJS5vCgkkKENDKSAkKExJQl9MREZMQUdTKSAkKExERkxBR1MpICQoTElCRkxBRykgLW8gJEAgJDwKCmluc3RhbGw6ICQoSU5TVF9MVUEpICQoSU5TVF9TTykKCiQoSU5TVF9MVUFESVIpLyUubHVhOiAuLyUubHVhCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgokKElOU1RfTElCRElSKS8lLiQoTElCX0VYVEVOU0lPTik6IC4vJS4kKExJQl9FWFRFTlNJT04pCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgouUEhPTlk6IGFsbCBpbnN0YWxsCg==
BIN_MK_DATA = QklOX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpCgpJTlNUX0xVQSA9ICQocGF0c3Vic3QgJS5sdWEsJChJTlNUX0JJTkRJUikvJSwgJChCSU5fTFVBKSkKCmFsbDoKCUAjIE5vdGhpbmcgdG8gZG8gaGVyZQoKaW5zdGFsbDogJChJTlNUX0xVQSkKCiQoSU5TVF9CSU5ESVIpLyU6IC4vJS5sdWEKCW1rZGlyIC1wICQoZGlyICRAKQoJY3AgJDwgJEAKCi5QSE9OWTogYWxsIGluc3RhbGwK

TEST_LUAROCKS_CFG_DATA = PCUgdGVtcGxhdGU6cHVzaChvcy5nZXRlbnYoIlRFU1QiKSA9PSAiMSIpICU+Cgpyb2Nrc190cmVlcyA9IHsKICB7IG5hbWUgPSAic3lzdGVtIiwKICAgIHJvb3QgPSAiPCUgcmV0dXJuIG9zLmdldGVudignQlVJTERfRElSJykgJT4vdGVzdC9sdWFfbW9kdWxlcyIKICB9IH0KCjwlIHRlbXBsYXRlOnBvcCgpOnB1c2gob3MuZ2V0ZW52KCJURVNUIikgfj0gIjEiKSAlPgoKcm9ja3NfdHJlZXMgPSB7CiAgeyBuYW1lID0gInN5c3RlbSIsCiAgICByb290ID0gIjwlIHJldHVybiBvcy5nZXRlbnYoJ0JVSUxEX0RJUicpICU+L2x1YV9tb2R1bGVzIgogIH0gfQoKPCUgdGVtcGxhdGU6cG9wKCkgJT4K
TEST_LUACOV_DATA = PCUKCiAgc3RyID0gcmVxdWlyZSgic2FudG9rdS5zdHJpbmciKQogIGZzID0gcmVxdWlyZSgic2FudG9rdS5mcyIpCiAgZ2VuID0gcmVxdWlyZSgic2FudG9rdS5nZW4iKQogIHZlYyA9IHJlcXVpcmUoInNhbnRva3UudmVjdG9yIikKCiAgZmlsZXMgPSBnZW4ucGFjaygibGliIiwgImJpbiIpOmZpbHRlcihmdW5jdGlvbiAoZGlyKQogICAgcmV0dXJuIGNoZWNrKGZzLmV4aXN0cyhkaXIpKQogIGVuZCk6bWFwKGZ1bmN0aW9uIChyZWxkaXIpCiAgICByZWxkaXIgPSByZWxkaXIgLi4gZnMucGF0aGRlbGltCiAgICByZXR1cm4gZnMuZmlsZXMocmVsZGlyLCB7IHJlY3Vyc2UgPSB0cnVlIH0pOm1hcChjaGVjayk6ZmlsdGVyKGZ1bmN0aW9uIChmcCkKICAgICAgcmV0dXJuIHZlYygibHVhIiwgImMiLCAiY3BwIik6aW5jbHVkZXMoc3RyaW5nLmxvd2VyKGZzLmV4dGVuc2lvbihmcCkpKQogICAgZW5kKTpwYXN0ZWwocmVsZGlyKQogIGVuZCk6ZmxhdHRlbigpOm1hcChmdW5jdGlvbiAocmVsZGlyLCBmcCkKICAgIGxvY2FsIG1vZCA9IGZzLnN0cmlwZXh0ZW5zaW9uKHN0ci5zdHJpcHByZWZpeChmcCwgcmVsZGlyKSk6Z3N1YigiLyIsICIuIikKICAgIHJldHVybiBtb2QsIGZwLCBmcy5qb2luKG9zLmdldGVudigiQlVJTERfRElSIiksIGZwKQogIGVuZCkKCiU+Cgptb2R1bGVzID0gewogIDwlIHJldHVybiBmaWxlczptYXAoZnVuY3Rpb24gKG1vZCwgcmVscGF0aCkKICAgIHJldHVybiBzdHIuaW50ZXJwKCJbXCIlbW9kXCJdID0gXCIlcmVscGF0aFwiIiwgeyBtb2QgPSBtb2QsIHJlbHBhdGggPSByZWxwYXRoIH0pCiAgZW5kKTpjb25jYXQoIixcbiIpICU+Cn0KCmluY2x1ZGUgPSB7CiAgPCUgcmV0dXJuIGZpbGVzOm1hcChmdW5jdGlvbiAoXywgXywgZnApCiAgICByZXR1cm4gc3RyLmludGVycCgiXCIlZnBcIiIsIHsgZnAgPSBmcCB9KQogIGVuZCk6Y29uY2F0KCIsXG4iKSAlPgp9Cg==
TEST_LUACHECK_DATA = cXVpZXQgPSAxCnN0ZCA9ICJtaW4iCmlnbm9yZSA9IHsgIjQzKiIgfSAtLSBVcHZhbHVlIHNoYWRvd2luZwpnbG9iYWxzID0geyAibmd4IiwgImppdCIgfQo=

export TEST_RUN_SH_DATA = IyEvYmluL3NoCgo8JQogIGdlbiA9IHJlcXVpcmUoInNhbnRva3UuZ2VuIikKICBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpCiAgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKQolPgoKLiAuL2x1YS5lbnYKCjwlIHJldHVybiB2ZWMud3JhcCh0ZXN0X2VudnMgb3Ige30pOmV4dGVuZChzdHIuc3BsaXQob3MuZ2V0ZW52KCJURVNUX0VOVlMiKSBvciAiIikpOmZpbHRlcihmdW5jdGlvbiAoZnApCiAgcmV0dXJuIG5vdCBzdHIuaXNlbXB0eShmcCkKZW5kKTptYXAoZnVuY3Rpb24gKGVudikKICByZXR1cm4gIi4gIiAuLiBlbnYKZW5kKTpjb25jYXQoIlxuIikgJT4KCnJtIC1mIGx1YWNvdi5zdGF0cy5vdXQgbHVhY292LnJlcG9ydC5vdXQgfHwgdHJ1ZQoKaWYgWyAtZCBzcGVjIF07IHRoZW4KIHRva3UgdGVzdCAtaSAiJExVQSAtbCBsdWFjb3YiIC0tbWF0Y2ggIl4uKiUubHVhJCIgc3BlYwpmaQoKaWYgWyAtZiBsdWFjb3YubHVhIF07IHRoZW4KICBsdWFjb3YgLWMgbHVhY292Lmx1YQpmaQoKaWYgWyAtZiBsdWFjb3YucmVwb3J0Lm91dCBdOyB0aGVuCiAgY2F0IGx1YWNvdi5yZXBvcnQub3V0IHwgYXdrICcvXlN1bW1hcnkvIHsgUCA9IE5SIH0gUCAmJiBOUiA+IFAgKyAxJwpmaQoKZWNobwoKaWYgWyAtZiBsdWFjaGVjay5sdWEgXTsgdGhlbgogIGx1YWNoZWNrIC0tY29uZmlnIGx1YWNoZWNrLmx1YSAkKGZpbmQgbGliIGJpbiBzcGVjIC1tYXhkZXB0aCAwIDI+L2Rldi9udWxsKQpmaQoKZWNobwo=

CONFIG_DEPS = $(lastword $(MAKEFILE_LIST))
CONFIG_DEPS += $(ROCKSPEC) $(LUAROCKS_MK) $(LIB_MK) $(BIN_MK)
CONFIG_DEPS += $(TEST_ROCKSPEC) $(TEST_LUAROCKS_MK) $(TEST_LIB_MK) $(TEST_BIN_MK) $(TEST_LUAROCKS_CFG)
CONFIG_DEPS += $(TEST_ENV) $(TEST_LUACOV_CFG) $(TEST_LUACHECK_CFG)
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/, $(LIB) $(BIN) $(TEST) $(RES) $(DEPS))
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/test/, $(LIB) $(BIN) $(RES) $(DEPS))

TARBALL = $(TARBALL_DIR).tar.gz
TARBALL_DIR = $(NAME)-$(VERSION)
TARBALL_SRCS = Makefile lib/Makefile bin/Makefile $(shell find lib bin deps res -type f 2>/dev/null)

all: $(CONFIG_DEPS)
	@echo "Running all"

install: all
	@echo "Running install"
	cd $(BUILD_DIR) && luarocks make $(ROCKSPEC)

test: all
	@echo "Running test"
	cd $(BUILD_DIR)/test && $(TEST_LUAROCKS) make $(TEST_ROCKSPEC) $(LUAROCKS_VARS)
	cd $(BUILD_DIR)/test && $(TEST_LUAROCKS) test $(TEST_ROCKSPEC) $(LUAROCKS_VARS)

iterate: all
	@echo "Running iterate"
	@while true; do \
		$(MAKE) test; \
		inotifywait -qqr -e close_write -e create -e delete bin lib test Makefile config.lua config.mk; \
	done

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

.PHONY: all test iterate install release check-release-status github-release luarocks-upload
.DEFAULT_GOAL: all
