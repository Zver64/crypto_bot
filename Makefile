build:
	mkdir -p build
	dart compile exe bin/dart_bot.dart -o build/dart_bot_linux --target-os linux --target-arch x64

deploy:
	scp build/dart_bot_linux root@91.197.3.215:/opt/telegram_bot/

clean:
	rm -rf build

.PHONY: build clean deploy
