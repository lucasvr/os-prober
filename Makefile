.PHONY: build_dirs
CFLAGS := -Os -g -Wall

ifeq ($(ARCH),)
	export ARCH := $(shell uname -m)
endif
ifeq ($(ARCH),x86_64)
	export ARCH = x86
endif

$(info Architecture: $(ARCH))

# NixOS uses the $out variable to indicate build output location
ifeq "$(out)" ""
	export LIB_DIR := /usr/lib/os-prober
	export BIN_DIR := /usr/bin/os-prober
	export SHARE_DIR := /usr/share/os-prober
else
	export LIB_DIR := $(out)/lib
	export BIN_DIR := $(out)/bin
	export SHARE_DIR := $(out)/share
endif

all: build/bin/os-prober build/bin/linux-boot-prober build/lib/newns

build_dirs:
	mkdir -p build/bin build/lib build/share/os-prober

build/lib/newns: build_dirs src/newns.c
	$(CC) $(CFLAGS) $(LDFLAGS) src/newns.c -o build/lib/newns

build/bin/os-prober: build/share/os-prober/common.sh src/os-prober
	./do-build-replace < src/os-prober > build/bin/os-prober
	chmod +x build/bin/os-prober

build/bin/linux-boot-prober: build/share/os-prober/common.sh src/linux-boot-prober
	./do-build-replace < src/linux-boot-prober > build/bin/linux-boot-prober
	chmod +x build/bin/linux-boot-prober

build/share/os-prober/common.sh: build_dirs src/common.sh
	./do-build-replace < src/common.sh > build/share/os-prober/common.sh

check: build/lib/newns
	./build/bin/os-prober
	./build/bin/os-prober | grep ':'
	./build/bin/linux-boot-prover
	./build/bin/linux-boot-prover | grep ':'

install: all
	mkdir -p $(LIB_DIR) $(BIN_DIR) $(SHARE_DIR)
	cp -r build/lib/* $(LIB_DIR)
	cp -a build/bin/* $(BIN_DIR)
	cp -a build/share/* $(SHARE_DIR)
	for probes in os os/init os/mounted linux-boot/mounted; do \
		mkdir -p $(LIB_DIR)/probes/$$probes; \
		cp src/probes/$$probes/common/* $(LIB_DIR)/probes/$$probes; \
		if [ -e "src/probes/$$probes/$(ARCH)" ]; then \
			cp -r src/probes/$$probes/$(ARCH)/* $(LIB_DIR)/probes/$$probes; \
		fi; \
	done

clean:
	rm -f newns
