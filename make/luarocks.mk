DEPS_DIRS = $(shell find deps/* -maxdepth 0 -type d 2>/dev/null)
DEPS_RESULTS = $(addsuffix /results.mk, $(DEPS_DIRS))

include $(DEPS_RESULTS)

all: $(DEPS_RESULTS) $(TEST_RUN_SH)
	@if [ -d lib ]; then $(MAKE) -C lib PARENT_DEPS_RESULTS="$(DEPS_RESULTS)"; fi
	@if [ -d bin ]; then $(MAKE) -C bin PARENT_DEPS_RESULTS="$(DEPS_RESULTS)"; fi

install: all
	@if [ -d lib ]; then $(MAKE) -C lib install; fi
	@if [ -d bin ]; then $(MAKE) -C bin install; fi

deps/%/results.mk: deps/%/Makefile
	@$(MAKE) -C "$(dir $@)"

# <% template:push(build.istest) %>

# TEST_RUN_SH = run.sh

# test: $(TEST_RUN_SH) $(WASM_TESTS)
# 	sh $(TEST_RUN_SH)

# $(TEST_RUN_SH): $(PREAMBLE)
# 	@echo "Generating '$@'"
# 	@sh -c 'echo $(TEST_RUN_SH_DATA) | base64 -d | $(TOKU_TEMPLATE_TEST) -f - -o "$@"'

# ifeq ($($(VPFX)_PROFILE),1)
# $(VPFX)_BUNDLE_FLAGS += --mod santoku.profile
# else
# $(VPFX)_BUNDLE_FLAGS += --no-close
# endif

# $(BUILD_DIR)/test/spec-bundled/%: $(BUILD_DIR)/test/spec/%.lua
# 	echo "Bundling '$<' -> '$(patsubst %.lua,%, $<)'"
# 	mkdir -p "$(patsubst $(BUILD_DIR)/test/spec/%,$(BUILD_DIR)/test/spec-bundler/%, $(dir $<))"
# 	$(CLIENT_VARS) toku bundle \
# 		--env $(VPFX)_WASM "$($(VPFX)_WASM)" \
# 		--env $(VPFX)_PROFILE "$($(VPFX)_PROFILE)" \
# 		--env $(VPFX)_SANITIZE "$($(VPFX)_SANITIZE)" \
# 		--env LUACOV_CONFIG "$(TEST_LUACOV_CFG)" \
# 		--path "$(shell $(TEST_LUAROCKS) path --lr-path)" \
# 		--cpath "$(shell $(TEST_LUAROCKS) path --lr-cpath)" \
# 		--mod luacov \
# 		--mod luacov.hook \
# 		--mod luacov.tick \
# 		--ignore debug \
# 		--cc emcc \
# 		--flags " -sASSERTIONS -sSINGLE_FILE -sALLOW_MEMORY_GROWTH -lnodefs.js -lnoderawfs.js" \
# 		--flags " $(LIB_CFLAGS) $(LIB_LDFLAGS)" \
# 		--flags " -I $(CLIENT_LUA_DIR)/include" \
# 		--flags " -L $(CLIENT_LUA_DIR)/lib" \
# 		--flags " -l lua" \
# 		--flags " -l m" \
# 		--input "$<" \
# 		--output-directory "$(patsubst $(BUILD_DIR)/test/spec/%,$(BUILD_DIR)/test/spec-bundler/%, $(dir $<))" \
# 		--output-prefix "$(notdir $(patsubst %.lua,%, $<))" \
# 		$($(VPFX)_BUNDLE_FLAGS)
# 	echo "Copying '$(patsubst %.lua,%, $<)' -> '$@'"
# 	mkdir -p "$(dir $@)"
# 	cp "$(patsubst $(BUILD_DIR)/test/spec/%.lua,$(BUILD_DIR)/test/spec-bundler/%, $<)" "$@"


# .PHONY: test

# <% template:pop() %>

.PHONY: all install
