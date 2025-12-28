import 'dart:io';
import 'package:dart_bot/constants.dart';
import 'package:dart_bot/handlers/conversation_handlers.dart';
import 'package:dart_bot/handlers/command_handlers.dart';
import 'package:dotenv/dotenv.dart';
import 'package:televerse/televerse.dart';
import 'package:televerse/plugins/conversation.dart';

void main() {
  String? token = Platform.environment['BOT_TOKEN'];

  if (token == null) {
    final DotEnv env = DotEnv()..load();
    token = env['BOT_TOKEN'];
  }

  if (token == null) {
    print('BOT_TOKEN not found in environment or .env file');
    exit(1);
  }

  final Bot bot = Bot(token);
  
  bot.plugin(ConversationPlugin());

  bot.use(createConversation(ConversationNames.threshold.name, setThresholdHandler));

  setupCommands(bot);

  bot.start();
}
