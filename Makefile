CMySQL=CMySQL-1.0.0
BUILDOPTS=-Xlinker -L/usr/lib -Xcc -IPackages/$(CMySQL)

SWIFTC=swiftc
SWIFT=swift
ifdef SWIFTPATH
    SWIFTC=$(SWIFTPATH)/bin/swiftc
    SWIFT=$(SWIFTPATH)/bin/swift
endif
OS := $(shell uname)
ifeq ($(OS),Darwin)
    SWIFTC=xcrun -sdk macosx swiftc
	BUILDOPTS=-Xcc -IPackages/$(CMySQL) -Xlinker -L/usr/local/lib -Xcc -I/usr/local/include/mysql
endif

all: build
	
build:
	$(SWIFT) build -v $(BUILDOPTS)
	
test:
	$(SWIFT) test
