include $(addprefix ../, $(PARENT_DEPS_RESULTS))

BIN_LUA = $(shell find * -name '*.lua')

INST_LUA = $(patsubst %.lua,$(INST_BINDIR)/%, $(BIN_LUA))

all:
	@# Nothing to do here

install: $(INST_LUA)

$(INST_BINDIR)/%: ./%.lua
	@mkdir -p $(dir $@)
	@cp $< $@

.PHONY: all install
