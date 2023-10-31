

include .build/preamble.mk

ifndef $(VPFX)_ENV
export $(VPFX)_ENV = default
endif

ROOT_DIR = $(PWD)
BUILD_DIR = $(ROOT_DIR)/.build/$($(VPFX)_ENV)

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
SRC_MK = $(BUILD_DIR)/src/Makefile
BIN_MK = $(BUILD_DIR)/bin/Makefile
LUACOV_CFG = $(BUILD_DIR)/test/luacov.lua
LUACHECK_CFG = $(BUILD_DIR)/test/luacheck.lua

PREAMBLE_DATA = TkFNRSA9IDwlIHJldHVybiBuYW1lICU+ClZFUlNJT04gPSA8JSByZXR1cm4gdmVyc2lvbiAlPgpWUEZYID0gPCUgcmV0dXJuIHZhcmlhYmxlX3ByZWZpeCAlPgoKZXhwb3J0IExVQSA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQSIpICU+CmV4cG9ydCBMVUFfUEFUSCA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQV9QQVRIIikgJT4KZXhwb3J0IExVQV9DUEFUSCA9IDwlIHJldHVybiBvcy5nZXRlbnYoIkxVQV9DUEFUSCIpICU+Cg==
ROCKSPEC_DATA = PCUgdmVjID0gcmVxdWlyZSgic2FudG9rdS52ZWN0b3IiKSAlPgo8JSBzdHIgPSByZXF1aXJlKCJzYW50b2t1LnN0cmluZyIpICU+CgpwYWNrYWdlID0gIjwlIHJldHVybiBuYW1lICU+Igp2ZXJzaW9uID0gIjwlIHJldHVybiB2ZXJzaW9uICU+Igpyb2Nrc3BlY19mb3JtYXQgPSAiMy4wIgoKc291cmNlID0gewogIHVybCA9ICI8JSByZXR1cm4gZG93bmxvYWQgJT4iLAp9CgpkZXNjcmlwdGlvbiA9IHsKICBob21lcGFnZSA9ICI8JSByZXR1cm4gaG9tZXBhZ2UgJT4iLAogIGxpY2Vuc2UgPSAiPCUgcmV0dXJuIGxpY2Vuc2UgJT4iCn0KCmRlcGVuZGVuY2llcyA9IHsKICA8JSByZXR1cm4gdmVjLndyYXAoZGVwZW5kZW5jaWVzIG9yIHt9KTptYXAoc3RyLnF1b3RlKTpjb25jYXQoIixcbiIpICU+Cn0KCnRlc3RfZGVwZW5kZW5jaWVzID0gewogIDwlIHJldHVybiB2ZWMud3JhcCh0ZXN0X2RlcGVuZGVuY2llcyBvciB7fSk6bWFwKHN0ci5xdW90ZSk6Y29uY2F0KCIsXG4iKSAlPgp9CgpidWlsZCA9IHsKICB0eXBlID0gIm1ha2UiLAogIHZhcmlhYmxlcyA9IHsKICAgIExJQl9FWFRFTlNJT04gPSAiJChMSUJfRVhURU5TSU9OKSIsCiAgfSwKICBidWlsZF92YXJpYWJsZXMgPSB7CiAgICBDQyA9ICIkKENDKSIsCiAgICBDRkxBR1MgPSAiJChDRkxBR1MpIiwKICAgIExJQkZMQUcgPSAiJChMSUJGTEFHKSIsCiAgICBMVUFfQklORElSID0gIiQoTFVBX0JJTkRJUikiLAogICAgTFVBX0lOQ0RJUiA9ICIkKExVQV9JTkNESVIpIiwKICAgIExVQV9MSUJESVIgPSAiJChMVUFfTElCRElSKSIsCiAgICBMVUEgPSAiJChMVUEpIiwKICB9LAogIGluc3RhbGxfdmFyaWFibGVzID0gewogICAgSU5TVF9QUkVGSVggPSAiJChQUkVGSVgpIiwKICAgIElOU1RfQklORElSID0gIiQoQklORElSKSIsCiAgICBJTlNUX0xJQkRJUiA9ICIkKExJQkRJUikiLAogICAgSU5TVF9MVUFESVIgPSAiJChMVUFESVIpIiwKICAgIElOU1RfQ09ORkRJUiA9ICIkKENPTkZESVIpIiwKICB9Cn0KCnRlc3QgPSB7CiAgdHlwZSA9ICJjb21tYW5kIiwKICBjb21tYW5kID0gIm1ha2UgdGVzdCIKfQo=
LUAROCKS_MK_DATA = ZXhwb3J0IFZQRlggPSA8JSByZXR1cm4gdmFyaWFibGVfcHJlZml4ICU+CgpERVBTX0RJUlMgPSAkKHNoZWxsIGZpbmQgZGVwcy8qIC1tYXhkZXB0aCAxIC10eXBlIGQgMj4vZGV2L251bGwpCkRFUFNfUkVTVUxUUyA9ICQoYWRkc3VmZml4IC9yZXN1bHRzLm1rLCAkKERFUFNfRElSUykpCgppbmNsdWRlICQoREVQU19SRVNVTFRTKQoKYWxsOiAkKERFUFNfUkVTVUxUUykgbHVhLmVudgoJQCQoTUFLRSkgLUUgImluY2x1ZGUgJChhZGRwcmVmaXggLi4vLCAkKERFUFNfUkVTVUxUUykpIiAtQyBzcmMKCUAkKE1BS0UpIC1FICJpbmNsdWRlICQoYWRkcHJlZml4IC4uLywgJChERVBTX1JFU1VMVFMpKSIgLUMgYmluCgp0ZXN0OgoJQHJtIC1mIGx1YWNvdi5zdGF0cy5vdXQgfHwgdHJ1ZQoJQC4gLi9sdWEuZW52ICYmICQoJChWUEZYKV9URVNUX1BSRUZJWCkgdG9rdSB0ZXN0IC1pICIkKExVQSkgLVcgLWwgbHVhY292IiAtLW1hdGNoICJeLiolLmx1YSQkIiB0ZXN0L3NwZWMKCUBsdWFjb3YgLWMgdGVzdC9sdWFjb3YubHVhIHx8IHRydWUKCUBjYXQgbHVhY292LnJlcG9ydC5vdXQgfCBhd2sgJy9eU3VtbWFyeS8geyBQID0gTlIgfSBQICYmIE5SID4gUCArIDEnCglAZWNobwoJQGx1YWNoZWNrIC0tY29uZmlnIHRlc3QvbHVhY2hlY2subHVhIHNyYyBiaW4gdGVzdC9zcGVjIHx8IHRydWUKCUBlY2hvCgppbnN0YWxsOiBhbGwKCUAkKE1BS0UpIC1DIHNyYyBpbnN0YWxsCglAJChNQUtFKSAtQyBiaW4gaW5zdGFsbAoKbHVhLmVudjoKCUBlY2hvIGV4cG9ydCBMVUE9IiQoTFVBKSIgPiBsdWEuZW52CgpkZXBzLyUvcmVzdWx0cy5tazogZGVwcy8lL01ha2VmaWxlCglAJChNQUtFKSAtQyAiJChkaXIgJEApIgoKLlBIT05ZOiBhbGwgdGVzdCBpbnN0YWxsCg==
LUAROCKS_CFG_DATA = cm9ja3NfdHJlZXMgPSB7CiAgeyBuYW1lID0gInN5c3RlbSIsCiAgICByb290ID0gIjwlIHJldHVybiBvcy5nZXRlbnYoJ0JVSUxEX0RJUicpICU+L2x1YV9tb2R1bGVzIgogIH0gfQo=
SRC_MK_DATA = U1JDX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpClNSQ19DID0gJChzaGVsbCBmaW5kICogLW5hbWUgJyouYycpClNSQ19PID0gJChTUkNfQzouYz0ubykKU1JDX1NPID0gJChTUkNfTzoubz0uJChMSUJfRVhURU5TSU9OKSkKCklOU1RfTFVBID0gJChhZGRwcmVmaXggJChJTlNUX0xVQURJUikvLCAkKFNSQ19MVUEpKQpJTlNUX1NPID0gJChhZGRwcmVmaXggJChJTlNUX0xJQkRJUikvLCAkKFNSQ19TTykpCgpMSUJfQ0ZMQUdTICs9IC1XYWxsIC1JJChMVUFfSU5DRElSKQpMSUJfTERGTEFHUyArPSAtV2FsbCAtTCQoTFVBX0xJQkRJUikKCmlmZXEgKCQoJChWUEZYKV9TQU5JVElaRSksMSkKTElCX0NGTEFHUyArPSAtZnNhbml0aXplPWFkZHJlc3MgLWZzYW5pdGl6ZT1sZWFrCkxJQl9MREZMQUdTICs9IC1mc2FuaXRpemU9YWRkcmVzcyAtZnNhbml0aXplPWxlYWsKZW5kaWYKCmFsbDogJChTUkNfTykgJChTUkNfU08pCgolLm86ICUuYwoJJChDQykgJChMSUJfQ0ZMQUdTKSAkKENGTEFHUykgLWMgLW8gJEAgJDwKCiUuJChMSUJfRVhURU5TSU9OKTogJS5vCgkkKENDKSAkKExJQl9MREZMQUdTKSAkKExERkxBR1MpICQoTElCRkxBRykgLW8gJEAgJDwKCmluc3RhbGw6ICQoSU5TVF9MVUEpICQoSU5TVF9TTykKCiQoSU5TVF9MVUFESVIpLyUubHVhOiAuLyUubHVhCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgokKElOU1RfTElCRElSKS8lLiQoTElCX0VYVEVOU0lPTik6IC4vJS4kKExJQl9FWFRFTlNJT04pCglta2RpciAtcCAkKGRpciAkQCkKCWNwICQ8ICRACgouUEhPTlk6IGFsbCBpbnN0YWxsCg==
BIN_MK_DATA = QklOX0xVQSA9ICQoc2hlbGwgZmluZCAqIC1uYW1lICcqLmx1YScpCgpJTlNUX0xVQSA9ICQocGF0c3Vic3QgJS5sdWEsJChJTlNUX0JJTkRJUikvJSwgJChCSU5fTFVBKSkKCmFsbDoKCUAjIE5vdGhpbmcgdG8gZG8gaGVyZQoKaW5zdGFsbDogJChJTlNUX0xVQSkKCiQoSU5TVF9CSU5ESVIpLyU6IC4vJS5sdWEKCW1rZGlyIC1wICQoZGlyICRAKQoJY3AgJDwgJEAKCi5QSE9OWTogYWxsIGluc3RhbGwK
LUACOV_DATA = PCUgc3RyID0gcmVxdWlyZSgic2FudG9rdS5zdHJpbmciKSAlPgo8JSBmcyA9IHJlcXVpcmUoInNhbnRva3UuZnMiKSAlPgoKbW9kdWxlcyA9IHsKICA8JQogICAgbG9jYWwgYnVpbGQgPSBvcy5nZXRlbnYoIkJVSUxEX0RJUiIpCiAgICBsb2NhbCBzcmMgPSBmcy5qb2luKGJ1aWxkLCAic3JjLyIpCiAgICByZXR1cm4gZnMuZmlsZXMoc3JjLCB7IHJlY3Vyc2UgPSB0cnVlIH0pOm1hcChjaGVjayk6ZmlsdGVyKGZ1bmN0aW9uIChmcCkKICAgICAgcmV0dXJuIGZzLmV4dGVuc2lvbihmcCkgPT0gImx1YSIKICAgIGVuZCk6bWFwKGZ1bmN0aW9uIChmcCkKICAgICAgbG9jYWwgZnAgPSBzdHIuc3RyaXBwcmVmaXgoZnAsIGJ1aWxkIC4uIGZzLnBhdGhkZWxpbSkKICAgICAgbG9jYWwgbW9kID0gZnMuc3RyaXBleHRlbnNpb24oc3RyLnN0cmlwcHJlZml4KGZwLCAic3JjLyIpKTpnc3ViKCIvIiwgIi4iKQogICAgICByZXR1cm4gbW9kLCBmcAogICAgZW5kKTptYXAoZnVuY3Rpb24gKG1vZCwgZnApCiAgICAgIHJldHVybiBzdHIuaW50ZXJwKCJbXCIlbW9kXCJdID0gXCIlZnBcIiIsIHsgbW9kID0gbW9kLCBmcCA9IGZwIH0pCiAgICBlbmQpOmNvbmNhdCgiLFxuIikKICAlPgp9Cg==
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
	@rm -rf "$(BUILD_DIR)"

tarball: $(BUILD_DIR)/$(TARBALL)

check-release-status:
	@if test -z "$(LUAROCKS_API_KEY)"; then echo "Missing LUAROCKS_API_KEY variable"; exit 1; fi
	@if ! git diff --quiet; then echo "Commit your changes first"; exit 1; fi

github-release-create: check-release-status tarball
	@gh release create $(VERSION) $(BUILD_DIR)/$(TARBALL)

luarocks-upload: check-release-status tarball
	@luarocks upload --skip-pack --api-key "$(LUAROCKS_API_KEY)" "$(ROCKSPEC)"

upload: check-release-status all
	@git tag "$(VERSION)"
	@git push --tags
	@git push
	@$(MAKE) tarball
	@$(MAKE) github-release-create
	@$(MAKE) luarocks-upload

$(BUILD_DIR)/$(TARBALL): all
	@rm -f $(BUILD_DIR)/$(TARBALL) || true
	@cd $(BUILD_DIR) && \
		tar --transform 's#^#$(TARBALL_DIR)/#' -czvf $(TARBALL) \
			$$(ls $(TARBALL_SRCS) 2>/dev/null)

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

.PHONY: all test iterate install touch clean clean-all upload check-release-status github-release-create luarocks-upload
.DEFAULT_GOAL: all
