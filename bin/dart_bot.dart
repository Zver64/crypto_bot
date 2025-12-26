import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:televerse/televerse.dart';

void main() {
  var env = DotEnv()..load();
  
  final token = env['BOT_TOKEN'] ?? Platform.environment['BOT_TOKEN'];
  if (token == null) {
    print('BOT_TOKEN not found');
    exit(1);
  }
  
  final bot = Bot(token);
  
  bot.command('start', (ctx) => ctx.reply('Hello from dart bot'));
  
  bot.start();
}
