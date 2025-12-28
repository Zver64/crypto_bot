import 'dart:async';
import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';
import 'package:televerse/plugins/conversation.dart';
import '../services/price_service.dart';
import '../services/bot_state.dart';

Future<void> setupCommands(Bot bot) async {
  bot.command('start', (ctx) => ctx.reply('Welcome! Use /menu to see available options.'));

  bot.command('subscribe', (ctx) async {
    final int? userId = ctx.from?.id;
    if (userId == null) return;
    
    final bool wasEmpty = BotState.subscribers.isEmpty;
    BotState.subscribers.add(userId);
    ctx.reply('✅ Subscribed to ${BotState.getThreshold()}% price alerts!');

    if (wasEmpty) {
      await checkPrices(bot, BotState.subscribers, BotState.getThreshold());
      final timer = Timer.periodic(
        const Duration(minutes: 5),
        (Timer _) => checkPrices(bot, BotState.subscribers, BotState.getThreshold()),
      );
      BotState.setTimer(timer);
      print('Started price monitoring');
    }
  });

  bot.command('unsubscribe', (ctx) {
    final int? userId = ctx.from?.id;
    if (userId == null) return;
    
    BotState.subscribers.remove(userId);
    ctx.reply('❌ Unsubscribed from price alerts');

    if (BotState.subscribers.isEmpty) {
      BotState.getTimer()?.cancel();
      BotState.setTimer(null);
      print('Stopped price monitoring');
    }
  });

  bot.command('setthreshold', (ctx) async {
    await ctx.conversation.enter('threshold');
  });

  bot.command('status', (ctx) {
    ctx.reply(
      'Current settings:\n'
      'Threshold: ${BotState.getThreshold().toStringAsFixed(1)}%\n'
      'Subscribers: ${BotState.subscribers.length}\n'
      'Monitoring: ${BotState.getTimer() != null ? "Active" : "Inactive"}'
    );
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
