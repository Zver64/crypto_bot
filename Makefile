build:
	mkdir -p build
	dart compile exe bin/dart_bot.dart -o build/dart_bot_linux --target-os linux --target-arch x64

deploy:
	scp build/dart_bot_linux root@91.197.3.215:/opt/telegram_bot/

start:
	ssh -f root@91.197.3.215 "cd /opt/telegram_bot && ./dart_bot_linux </dev/null &>./bot.log &" 

stop:
	ssh root@91.197.3.215 "pkill -f dart_bot_linux" && echo 'Bot stopped' || echo 'No bot process found'

clean:
	rm -rf build

.PHONY: build clean deploy start stop
