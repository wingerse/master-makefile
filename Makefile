PROJ_NAME ?= project
CC = clang
INCLUDE_PATHS ?=
LINK_PATHS ?=
LIBS ?=
# -pg -mfentry
CFLAGS += -std=gnu11 -march=x86-64 -msse3 \
-Werror -Wall -Wextra -Wpedantic -Wconversion \
-Wno-unused-parameter -Wno-missing-braces -Wno-missing-field-initializers -Wno-format \
-Wno-newline-eof -Wno-language-extension-token -Wno-gnu-zero-variadic-macro-arguments \
-Wno-gnu-empty-struct -Wno-error=unused-function

ifdef RELEASE
CFLAGS += -O2 -DNDEBUG
BUILD_FOLDER = release
else
CFLAGS += -g -D_DEBUG -DDEBUG -O0
BUILD_FOLDER = debug
endif

ifdef UNIT_TEST
CFLAGS += -DUNIT_TEST
BUILD_FOLDER := ut-$(BUILD_FOLDER)
endif

OUTPUT_FOLDER = bin
ifdef LIB
INCLUDE_PATHS += -Iinclude
ifndef UNIT_TEST
OUTPUT_FOLDER = lib
TARGET_NAME := $(PROJ_NAME).a
endif
endif

src = $(shell find src -name '*.c' -type f | paste -s -)
res = $(shell find res -name '*' -type f 2> /dev/null | paste -s -)

TARGET = $(OUTPUT_FOLDER)/$(BUILD_FOLDER)/$(TARGET_NAME)
$(shell mkdir -p $(OUTPUT_FOLDER)/$(BUILD_FOLDER))

obj = $(patsubst src/%.c,obj/$(BUILD_FOLDER)/%.o,$(src))
obj/$(BUILD_FOLDER)/%.o: src/%.c
	mkdir -p $(@D)
	$(CC) -c $< -o $@ $(INCLUDE_PATHS) $(CFLAGS) -MP -MMD

res_obj = $(patsubst res/%,obj/res/%.o,$(res))
obj/res/%.o: res/%
	mkdir -p $(@D)
	embed -h $< > $(patsubst %.o, %.h, $@)
	embed $< | $(CC) -c -o $@ -xc -

main: $(res_obj) $(obj)
ifdef LIB
ifndef UNIT_TEST
	ar rcs $(TARGET) $(res_obj) $(obj)
else
	$(CC) -o $(TARGET) $(res_obj) $(obj) $(LINK_PATHS) $(LIBS) $(CFLAGS)
endif
else
	$(CC) -o $(TARGET) $(res_obj) $(obj) $(LINK_PATHS) $(LIBS) $(CFLAGS)
endif

run: main
	$(TARGET)

install:
ifdef LIB
	cp -n lib/release/$(TARGET_NAME) /usr/local/lib/$(TARGET_NAME)
	cp -rn include/$(PROJ_NAME)/ /usr/local/include/$(PROJ_NAME)
else
	cp -n bin/release/$(TARGET_NAME) /usr/local/bin/$(TARGET_NAME)
endif

.PHONY: clean
.PHONY: clean-debug
.PHONY: clean-release
.PHONY: clean-res

clean:
	rm -rf obj/

clean-debug:
	rm -rf obj/debug/

clean-release:
	rm -rf obj/release/

clean-res:
	rm -rf obj/res/

-include $(obj:.o=.d)

