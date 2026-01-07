import 'dart:async';
import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';
import 'package:televerse/plugins/conversation.dart';
import '../services/subscription_service.dart';

Future<void> setupCommands(Bot bot) async {
  bot.command('start', (ctx) => ctx.reply('Welcome! Use /menu to see available options.'));

  bot.command('subscribe', (ctx) async {
    final int? userId = ctx.from?.id;
    if (userId == null) return;
    
    final message = await SubscriptionService.subscribe(userId, bot);
    ctx.reply(message);
  });

  bot.command('unsubscribe', (ctx) {
    final int? userId = ctx.from?.id;
    if (userId == null) return;
    
    final message = SubscriptionService.unsubscribe(userId);
    ctx.reply(message);
  });

  bot.command('setthreshold', (ctx) async {
    await ctx.conversation.enter('threshold');
  });

  bot.command('status', (ctx) {
    ctx.reply(SubscriptionService.getStatus());
  });
}

Future<void> setCommandsAPI(Bot bot) async {
  await bot.api.setMyCommands([
    BotCommand(command: 'start', description: 'Начать работу'),
    BotCommand(command: 'subscribe', description: 'Подписаться на уведомления'),
    BotCommand(command: 'unsubscribe', description: 'Отписаться от уведомлений'),
    BotCommand(command: 'setthreshold', description: 'Установить порог уведомлений'),
    BotCommand(command: 'status', description: 'Показать текущие настройки'),
  ], scope: BotCommandScopeAllPrivateChats());

  await bot.api.setChatMenuButton(MenuButtonCommands());
}
