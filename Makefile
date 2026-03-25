APP_NAME = Wren
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS  = $(APP_BUNDLE)/Contents
MACOS     = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources
BINARY    = $(MACOS)/$(APP_NAME)
ICNS_SRC  = wren.icns

SOURCES = $(wildcard Sources/*.swift)

.PHONY: all clean run

all: $(BINARY) $(CONTENTS)/Info.plist $(RESOURCES)/wren.icns

$(BINARY): $(SOURCES) | $(MACOS)
	swiftc $(SOURCES) -o $@ -framework AppKit

$(CONTENTS)/Info.plist: Info.plist | $(CONTENTS)
	cp $< $@

$(RESOURCES)/wren.icns: $(ICNS_SRC) | $(RESOURCES)
	cp $< $@

$(MACOS):
	mkdir -p $@

$(CONTENTS):
	mkdir -p $@

$(RESOURCES):
	mkdir -p $@

$(BUILD_DIR):
	mkdir -p $@

run: all
	open $(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DIR)
