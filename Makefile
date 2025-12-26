build-linux:
	mkdir -p build
	dart compile exe bin/dart_bot.dart -o build/dart_bot_linux --target-os linux --target-arch x64

clean:
	rm -rf build

.PHONY: build-linux clean
