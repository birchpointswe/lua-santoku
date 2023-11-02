

include .build/preamble.mk

ifndef $(VPFX)_ENV
export $(VPFX)_ENV = default
endif

ROOT_DIR = $(PWD)
BUILD_BASE_DIR = $(ROOT_DIR)/.build
BUILD_DIR = $(BUILD_BASE_DIR)/$($(VPFX)_ENV)

TOKU_TEMPLATE = BUILD_DIR="$(BUILD_DIR)" toku template -M -c config.lua
ROCKSPEC = $(BUILD_DIR)/$(NAME)-$(VERSION).rockspec

SRC = $(shell find src -type f 2>/dev/null)
BIN = $(shell find bin -type f 2>/dev/null)
TEST = $(shell find test -type f 2>/dev/null)
RES = $(shell find res -type f 2>/dev/null)
DEPS = $(shell find deps -type f 2>/dev/null)

LUAROCKS = LUAROCKS_CONFIG=$(LUAROCKS_CFG) luarocks
LUAROCKS_MK = $(BUILD_DIR)/Makefile
LUAROCKS_CFG = $(BUILD_DIR)/luarocks.lua

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

PREAMBLE_DATA = TkFNRSA9IDwlIHJldHVybiBuYW1lICU+ClZFUlNJT04gPSA8JSByZXR1cm4gdmVyc2lvbiAlPgpWUEZYID0gPCUgcmV0dXJuIHZhcmlhYmxlX3ByZWZpeCAlPgoKZXhwb3J0IExVQSA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQSIpICU+CmV4cG9ydCBMVUFfUEFUSCA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQV9QQVRIIikgJT4KZXhwb3J0IExVQV9DUEFUSCA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQV9DUEFUSCIpICU+CgpleHBvcnQgJChWUEZYKV9QVUJMSUMgPSA8JSByZXR1cm4gcHVibGljIGFuZCAiMSIgb3IgIjAiICU+Cg==
ROCKSPEC_DATA = PCUgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKSAlPgo8JSBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpICU+CgpwYWNrYWdlID0gIjwlIHJldHVybiBuYW1lICU+Igp2ZXJzaW9uID0gIjwlIHJldHVybiB2ZXJzaW9uICU+Igpyb2Nrc3BlY19mb3JtYXQgPSAiMy4wIgoKc291cmNlID0gewogIHVybCA9ICI8JSByZXR1cm4gZG93bmxvYWQgJT4iLAp9CgpkZXNjcmlwdGlvbiA9IHsKICBob21lcGFnZSA9ICI8JSByZXR1cm4gaG9tZXBhZ2UgJT4iLAogIGxpY2Vuc2UgPSAiPCUgcmV0dXJuIGxpY2Vuc2UgJT4iCn0KCmRlcGVuZGVuY2llcyA9IHsKICA8JSByZXR1cm4gdmVjLndyYXAoZGVwZW5kZW5jaWVzIG9yIHt9KTptYXAoc3RyLnF1b3RlKTpjb25jYXQoIixcbiIpICU+Cn0KCnRlc3RfZGVwZW5kZW5jaWVzID0gewogIDwlIHJldHVybiB2ZWMud3JhcCh0ZXN0X2RlcGVuZGVuY2llcyBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9CgpidWlsZCA9IHsKICB0eXBlID0gIm1ha2UiLAogIHZhcmlhYmxlcyA9IHsKICAgIExJQl9FWFRFTlNJT04gPSAiJChMSUJfRVhURU5TSU9OKSIsCiAgfSwKICBidWlsZF92YXJpYWJsZXMgPSB7CiAgICBDQyA9ICIkKENDKSIsCiAgICBDRkxBR1MgPSAiJChDRkxBR1MpIiwKICAgIExJQkZMQUcgPSAiJChMSUJGTEFHKSIsCiAgICBMVUFfQklORElSID0gIiQoTFVBX0JJTkRJUikiLAogICAgTFVBX0lOQ0RJUiA9ICIkKExVQV9JTkNESVIpIiwKICAgIExVQV9MSUJESVIgPSAiJChMVUFfTElCRElSKSIsCiAgICBMVUEgPSAiJChMVUEpIiwKICB9LAogIGluc3RhbGxfdmFyaWFibGVzID0gewogICAgSU5TVF9QUkVGSVggPSAiJChQUkVGSVgpIiwKICAgIElOU1RfQklORElSID0gIiQoQklORElSKSIsCiAgICBJTlNUX0xJQkRJUiA9ICIkKExJQkRJUikiLAogICAgSU5TVF9MVUFESVIgPSAiJChMVUFESVIpIiwKICAgIElOU1RfQ09ORkRJUiA9ICIkKENPTkZESVIpIiwKICB9Cn0KCnRlc3QgPSB7CiAgdHlwZSA9ICJjb21tYW5kIiwKICBjb21tYW5kID0gIm1ha2UgdGVzdCIKfQo=
LUAROCKS_MK_DATA = ZXhwb3J0IFZQRlggPSA8JSByZXR1cm4gdmFyaWFibGVfcHJlZml4ICU+CgpERVBTX0RJUlMgPSAkKHNoZWxsIGZpbmQgZGVwcy8qIC1tYXhkZXB0aCAxIC10eXBlIGQgMj4vZGV2L251bGwpCkRFUFNfUkVTVUxUUyA9ICQoYWRkc3VmZml4IC9yZXN1bHRzLm1rLCAkKERFUFNfRElSUykpCgppbmNsdWRlICQoREVQU19SRVNVTFRTKQoKYWxsOiAkKERFUFNfUkVTVUxUUykgbHVhLmVudgoJQGlmIFsgLWQgc3JjIF07IHRoZW4gJChNQUtFKSAtRSAiaW5jbHVkZSAkKGFkZHByZWZpeCAuLi8sICQoREVQU19SRVNVTFRTKSkiIC1DIHNyYzsgZmkKCUBpZiBbIC1kIGJpbiBdOyB0aGVuICQoTUFLRSkgLUUgImluY2x1ZGUgJChhZGRwcmVmaXggLi4vLCAkKERFUFNfUkVTVUxUUykpIiAtQyBiaW47IGZpCgppbnN0YWxsOiBhbGwKCUBpZiBbIC1kIHNyYyBdOyB0aGVuICQoTUFLRSkgLUMgc3JjIGluc3RhbGw7IGZpCglAaWYgWyAtZCBiaW4gXTsgdGhlbiAkKE1BS0UpIC1DIGJpbiBpbnN0YWxsOyBmaQoKaWZlcSAoJChzaGVsbCB0ZXN0IC1kIHRlc3QgJiYgZWNobyAxKSwxKQoKdGVzdDoKCUBybSAtZiBsdWFjb3Yuc3RhdHMub3V0IGx1YWNvdi5yZXBvcnQub3V0IHx8IHRydWUKCUBpZiBbIC1kIHRlc3Qvc3BlYyBdOyB0aGVuIC4gLi9sdWEuZW52ICYmICQoJChWUEZYKV9URVNUX1BSRUZJWCkgXAoJCXRva3UgdGVzdCAtaSAiJChMVUEpIC1sIGx1YWNvdiIgLS1tYXRjaCAiXi4qJS5sdWEkJCIgdGVzdC9zcGVjOyBmaQoJQGlmIFsgLWYgdGVzdC9sdWFjb3YubHVhIF07IHRoZW4gbHVhY292IC1jIHRlc3QvbHVhY292Lmx1YTsgZmkKCUBpZiBbIC1mIGx1YWNvdi5yZXBvcnQub3V0IF07IHRoZW4gY2F0IGx1YWNvdi5yZXBvcnQub3V0IHwgYXdrICcvXlN1bW1hcnkvIHsgUCA9IE5SIH0gUCAmJiBOUiA+IFAgKyAxJzsgZmkKCUBlY2hvCglAaWYgWyAtZiB0ZXN0L2x1YWNoZWNrLmx1YSBdOyB0aGVuIGx1YWNoZWNrIC0tY29uZmlnIHRlc3QvbHVhY2hlY2subHVhICQkKGZpbmQgc3JjIGJpbiB0ZXN0L3NwZWMgLW1heGRlcHRoIDAgMj4vZGV2L251bGwpOyBmaQoJQGVjaG8KCmVsc2UKCnRlc3Q6CgplbmRpZgoKbHVhLmVudjoKCUBlY2hvIGV4cG9ydCBMVUE9IiQoTFVBKSIgPiBsdWEuZW52CgpkZXBzLyUvcmVzdWx0cy5tazogZGVwcy8lL01ha2VmaWxlCglAJChNQUtFKSAtQyAiJChkaXIgJEApIgoKLlBIT05ZOiBhbGwgdGVzdCBpbnN0YWxsCg==
LUAROCKS_CFG_DATA = cm9ja3NfdHJlZXMgPSB7CiAgeyBuYW1lID0gInN5c3RlbSIsCiAgICByb290ID0gIjwlIHJldHVybiBvcy5nZXRlbnYoJ0JVSUxEX0RJUicpICU+L2x1YV9tb2R1bGVzIgogIH0gfQo=
SRC_MK_DATA = U1JDX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpClNSQ19DID0gJChzaGVsbCBmaW5kICogLW5hbWUgJyouYycpClNSQ19PID0gJChTUkNfQzouYz0ubykKU1JDX1NPID0gJChTUkNfTzoubz0uJChMSUJfRVhURU5TSU9OKSkKCklOU1RfTFVBID0gJChhZGRwcmVmaXggJChJTlNUX0xVQURJUikvLCAkKFNSQ19MVUEpKQpJTlNUX1NPID0gJChhZGRwcmVmaXggJChJTlNUX0xJQkRJUikvLCAkKFNSQ19TTykpCgpMSUJfQ0ZMQUdTICs9IC1XYWxsIC1JJChMVUFfSU5DRElSKQpMSUJfTERGTEFHUyArPSAtV2FsbCAtTCQoTFVBX0xJQkRJUikKCmlmZXEgKCQoJChWUEZYKV9TQU5JVElaRSksMSkKTElCX0NGTEFHUyArPSAtZnNhbml0aXplPWFkZHJlc3MgLWZzYW5pdGl6ZT1sZWFrCkxJQl9MREZMQUdTICs9IC1mc2FuaXRpemU9YWRkcmVzcyAtZnNhbml0aXplPWxlYWsKZW5kaWYKCmFsbDogJChTUkNfTykgJChTUkNfU08pCgolLm86ICUuYwoJJChDQykgJChMSUJfQ0ZMQUdTKSAkKENGTEFHUykgLWMgLW8gJEAgJDwKCiUuJChMSUJfRVhURU5TSU9OKTogJS5vCgkkKENDKSAkKExJQl9MREZMQUdTKSAkKExERkxBR1MpICQoTElCRkxBRykgLW8gJEAgJDwKCmluc3RhbGw6ICQoSU5TVF9MVUEpICQoSU5TVF9TTykKCiQoSU5TVF9MVUFESVIpLyUubHVhOiAuLyUubHVhCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgokKElOU1RfTElCRElSKS8lLiQoTElCX0VYVEVOU0lPTik6IC4vJS4kKExJQl9FWFRFTlNJT04pCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgouUEhPTlk6IGFsbCBpbnN0YWxsCg==
BIN_MK_DATA = QklOX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpCgpJTlNUX0xVQSA9ICQocGF0c3Vic3QgJS5sdWEsJChJTlNUX0JJTkRJUikvJSwgJChCSU5fTFVBKSkKCmFsbDoKCUAjIE5vdGhpbmcgdG8gZG8gaGVyZQoKaW5zdGFsbDogJChJTlNUX0xVQSkKCiQoSU5TVF9CSU5ESVIpLyU6IC4vJS5sdWEKCW1rZGlyIC1wICQoZGlyICRAKQoJY3AgJDwgJEAKCi5QSE9OWTogYWxsIGluc3RhbGwK
LUACOV_DATA = PCUgc3RyID0gcmVxdWlyZSgic2FudG9rdS5zdHJpbmciKSAlPgo8JSBmcyA9IHJlcXVpcmUoInNhbnRva3UuZnMiKSAlPgo8JSBnZW4gPSByZXF1aXJlKCJzYW50b2t1LmdlbiIpICU+CjwlIHZlYyA9IHJlcXVpcmUoInNhbnRva3UudmVjdG9yIikgJT4KCjwlIGZpbGVzID0gZ2VuLnBhY2soInNyYyIsICJiaW4iKTpmaWx0ZXIoZnVuY3Rpb24gKGRpcikKICByZXR1cm4gY2hlY2soZnMuZXhpc3RzKGRpcikpCmVuZCk6bWFwKGZ1bmN0aW9uIChyZWxkaXIpCiAgcmVsZGlyID0gcmVsZGlyIC4uIGZzLnBhdGhkZWxpbQogIHJldHVybiBmcy5maWxlcyhyZWxkaXIsIHsgcmVjdXJzZSA9IHRydWUgfSk6bWFwKGNoZWNrKTpmaWx0ZXIoZnVuY3Rpb24gKGZwKQogICAgcmV0dXJuIHZlYygibHVhIiwgImMiLCAiY3BwIik6aW5jbHVkZXMoc3RyaW5nLmxvd2VyKGZzLmV4dGVuc2lvbihmcCkpKQogIGVuZCk6cGFzdGVsKHJlbGRpcikKZW5kKTpmbGF0dGVuKCk6bWFwKGZ1bmN0aW9uIChyZWxkaXIsIGZwKQogIGxvY2FsIG1vZCA9IGZzLnN0cmlwZXh0ZW5zaW9uKHN0ci5zdHJpcHByZWZpeChmcCwgcmVsZGlyKSk6Z3N1YigiLyIsICIuIikKICByZXR1cm4gbW9kLCBmcCwgZnMuam9pbihvcy5nZXRlbnYoIkJVSUxEX0RJUiIpLCBmcCkKZW5kKSAlPgoKbW9kdWxlcyA9IHsKICA8JSByZXR1cm4gZmlsZXM6bWFwKGZ1bmN0aW9uIChtb2QsIHJlbHBhdGgpCiAgICByZXR1cm4gc3RyLmludGVycCgiW1wiJW1vZFwiXSA9IFwiJXJlbHBhdGhcIiIsIHsgbW9kID0gbW9kLCByZWxwYXRoID0gcmVscGF0aCB9KQogIGVuZCk6Y29uY2F0KCIsXG4iKSAlPgp9CgppbmNsdWRlID0gewogIDwlIHJldHVybiBmaWxlczptYXAoZnVuY3Rpb24gKF8sIF8sIGZwKQogICAgcmV0dXJuIHN0ci5pbnRlcnAoIlwiJWZwXCIiLCB7IGZwID0gZnAgfSkKICBlbmQpOmNvbmNhdCgiLFxuIikgJT4KfQo=
LUACHECK_DATA = cXVpZXQgPSAxCnN0ZCA9ICJtaW4iCmlnbm9yZSA9IHsgIjQzKiIgfSAtLSBVcHZhbHVlIHNoYWRvd2luZwpnbG9iYWxzID0geyAibmd4IiwgImppdCIgfQo=

CONFIG_DEPS = $(lastword $(MAKEFILE_LIST))
CONFIG_DEPS += $(ROCKSPEC) $(LUAROCKS_MK) $(LUAROCKS_CFG) $(SRC_MK) $(BIN_MK) $(LUACOV_CFG) $(LUACHECK_CFG)
CONFIG_DEPS += $(addprefix $(BUILD_DIR)/, $(SRC) $(BIN) $(TEST) $(RES) $(DEPS))

TARBALL = $(TARBALL_DIR).tar.gz
TARBALL_DIR = $(NAME)-$(VERSION)
TARBALL_SRCS = Makefile src/Makefile bin/Makefile $(shell find src bin deps res -type f 2>/dev/null)

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
	@rm -rf "$(BUILD_BASE_DIR)"

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

$(LUAROCKS_CFG):
	@echo "Generating '$@'"
	@sh -c 'echo $(LUAROCKS_CFG_DATA) | base64 -d | BUILD_DIR="$(BUILD_DIR)" $(TOKU_TEMPLATE) -f - -o "$@"'

$(BUILD_DIR).build/preamble.mk: $(LUAROCKS_CFG) config.lua
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
		*) \
			echo "Templating '$<' -> '$@'"; \
			$(TOKU_TEMPLATE) -f "$<" -o "$@";; \
	esac

-include $(shell find $(BUILD_DIR) -regex ".*/deps/.*/.*" -prune -o -name "*.d" -print 2>/dev/null)

.PHONY: all test iterate install touch clean clean-all release check-release-status github-release luarocks-upload
.DEFAULT_GOAL: all
