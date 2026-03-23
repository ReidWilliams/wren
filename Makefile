APP_NAME = Wren
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS  = $(APP_BUNDLE)/Contents
MACOS     = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources
BINARY    = $(MACOS)/$(APP_NAME)
ICONSET   = $(BUILD_DIR)/wren.iconset
ICNS      = $(BUILD_DIR)/wren.icns

SOURCES = $(wildcard Sources/*.swift)

.PHONY: all clean run

all: $(BINARY) $(CONTENTS)/Info.plist $(RESOURCES)/wren.icns

$(BINARY): $(SOURCES) | $(MACOS)
	swiftc $(SOURCES) -o $@ -framework AppKit

$(CONTENTS)/Info.plist: Info.plist | $(CONTENTS)
	cp $< $@

$(RESOURCES)/wren.icns: $(ICNS) | $(RESOURCES)
	cp $< $@

$(ICNS): $(ICONSET) | $(BUILD_DIR)
	iconutil -c icns $(ICONSET) -o $(ICNS)

$(ICONSET): wren.png | $(BUILD_DIR)
	mkdir -p $(ICONSET)
	sips -z 16   16   wren.png -o $(ICONSET)/icon_16x16.png
	sips -z 32   32   wren.png -o $(ICONSET)/icon_16x16@2x.png
	sips -z 32   32   wren.png -o $(ICONSET)/icon_32x32.png
	sips -z 64   64   wren.png -o $(ICONSET)/icon_32x32@2x.png
	sips -z 128  128  wren.png -o $(ICONSET)/icon_128x128.png
	sips -z 256  256  wren.png -o $(ICONSET)/icon_128x128@2x.png
	sips -z 256  256  wren.png -o $(ICONSET)/icon_256x256.png
	sips -z 512  512  wren.png -o $(ICONSET)/icon_256x256@2x.png
	sips -z 512  512  wren.png -o $(ICONSET)/icon_512x512.png
	sips -z 1024 1024 wren.png -o $(ICONSET)/icon_512x512@2x.png

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
