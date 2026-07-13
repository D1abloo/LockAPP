.PHONY: generate build run test archive clean

DERIVED_DATA ?= .build/DerivedData
ARCHIVE_PATH ?= .build/LockCode.xcarchive

generate:
	xcodegen generate

build: generate
	xcodebuild -project LockCode.xcodeproj -scheme LockCode -configuration Debug -destination 'platform=macOS' -derivedDataPath '$(DERIVED_DATA)' build

run: build
	open '$(DERIVED_DATA)/Build/Products/Debug/LockCode.app'

test: generate
	xcodebuild -project LockCode.xcodeproj -scheme LockCode -configuration Debug -destination 'platform=macOS' -derivedDataPath '$(DERIVED_DATA)' test

archive: generate
	xcodebuild -project LockCode.xcodeproj -scheme LockCode -configuration Release -destination 'generic/platform=macOS' -derivedDataPath '$(DERIVED_DATA)' -archivePath '$(ARCHIVE_PATH)' archive

clean:
	rm -rf LockCode.xcodeproj .build
