LIB_NAME ?= $(NAME)

LIB_SRC ?= $(shell find src/$(LIB_NAME) -name '*.lua')
LIB_DIST ?= $(patsubst src/%, $(INST_LUADIR)/%, $(LIB_SRC))

LIB_ROCKSPEC ?= $(BUILD_DIR)/$(LIB_NAME)-$(VERSION).rockspec
LIB_ROCKSPEC_T ?= config/lib.rockspec

LIB_LUACOV_CFG ?= $(BUILD_DIR)/luacov.lua
LIB_LUACOV_CFG_T ?= test/luacov.lua
LIB_LUACOV_STATS_FILE ?= $(BUILD_DIR)/luacov.stats.out
LIB_LUACOV_REPORT_FILE ?= $(BUILD_DIR)/luacov.report.out

TEST_LUA_PATH ?= src/?.lua;$(LUA_PATH)
TEST_LUA_CPATH ?= $(LUA_CPATH)

lib-install: $(LIB_ROCKSPEC)
	luarocks make $(LIB_ROCKSPEC) $(ARGS)

luarocks-lib-install: $(LIB_DIST)

lib-upload: $(LIB_ROCKSPEC)
	cd "$(BUILD_DIR)" && \
		luarocks upload --skip-pack --api-key "$(LUAROCKS_API_KEY)" "../$(LIB_ROCKSPEC)" $(ARGS)

test: $(LIB_ROCKSPEC)
	@luarocks test $(LIB_ROCKSPEC)

iterate: $(LIB_ROCKSPEC)
	@while true; do \
		luarocks test $(LIB_ROCKSPEC); \
		inotifywait -qqr -e close_write -e create -e delete -e delete \
			Makefile src config test; \
	done

luarocks-test: $(LIB_ROCKSPEC) $(LIB_LUACOV_CFG)
	@if LUACOV_CONFIG="$(PWD)/$(LIB_LUACOV_CFG)" \
  LUA_PATH="$(TEST_LUA_PATH)" \
	LUA_CPATH="$(TEST_LUA_CPATH)" \
		$(TOKU) test -s test/spec -i "$(LUA) -l luacov" -m ".*.lua$$"; \
	then \
		luacov -c $(PWD)/$(LIB_LUACOV_CFG); \
		cat "$(LIB_LUACOV_REPORT_FILE)" | \
			awk '/^Summary/ { P = NR } P && NR > P + 1'; \
		echo; \
		luacheck --config test/luacheck.lua src || true; \
		echo; \
  fi

$(INST_LUADIR)/$(LIB_NAME)/%: src/$(LIB_NAME)/%
	test -n "$(INST_LUADIR)"
	mkdir -p "$(dir $@)"
	cp "$^" "$@"

$(LIB_ROCKSPEC): $(LIB_ROCKSPEC_T)
	NAME="$(LIB_NAME)" VERSION="$(VERSION)" \
	HOMEPAGE="$(HOMEPAGE)" LICENSE="$(LICENSE)" \
	GIT_URL="$(GIT_URL)" \
		$(TOKU) template -f "$^" -o "$@"

$(LIB_LUACOV_CFG): $(LIB_LUACOV_CFG_T)
	STATS_FILE="$(PWD)/$(LIB_LUACOV_STATS_FILE)" \
	REPORT_FILE="$(PWD)/$(LIB_LUACOV_REPORT_FILE)" \
		$(TOKU) template -f "$^" -o "$@"

.PHONY: lib-install luarocks-lib-install lib-upload test iterate luarocks-test
