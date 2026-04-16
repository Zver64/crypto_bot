import 'dart:async';
import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';
import 'package:televerse/plugins/conversation.dart';
import '../services/subscription_service.dart';
import '../services/price_service.dart';

Future<void> setupCommands(Bot bot) async {
  bot.command(
    'start',
    (ctx) => ctx.reply('Welcome! Use /menu to see available options.'),
  );

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

  bot.command('setmcap', (ctx) async {
    await ctx.conversation.enter('mcap');
  });

  bot.command('status', (ctx) {
    ctx.reply(SubscriptionService.getStatus());
  });

  bot.command('analyze', (ctx) async {
    await ctx.conversation.enter('analyze');
  });

  bot.callbackQuery(RegExp(r'^analyze:'), (ctx) async {
    final callbackData = ctx.callbackQuery?.data ?? '';
    final coinId = callbackData.replaceFirst('analyze:', '').trim();

    if (coinId.isEmpty) {
      await ctx.answerCallbackQuery(
        text: 'Could not determine the selected coin.',
        showAlert: true,
      );
      return;
    }

    await ctx.answerCallbackQuery(text: 'Analyzing $coinId...');
    final message = await analyzeCoinById(coinId);
    await ctx.editMessageText(message, parseMode: ParseMode.html);
  });

  bot.command('faq', (ctx) {
    ctx.reply(getAnalyzeFaqMessage(), parseMode: ParseMode.html);
  });
}

Future<void> setCommandsAPI(Bot bot) async {
  await bot.api.setMyCommands([
    BotCommand(command: 'start', description: 'Начать работу'),
    BotCommand(command: 'subscribe', description: 'Подписаться на уведомления'),
    BotCommand(
      command: 'unsubscribe',
      description: 'Отписаться от уведомлений',
    ),
    BotCommand(
      command: 'setthreshold',
      description: 'Установить порог уведомлений',
    ),
    BotCommand(command: 'setmcap', description: 'Установить cap anchors'),
    BotCommand(command: 'status', description: 'Показать текущие настройки'),
    BotCommand(command: 'analyze', description: 'Анализ монеты'),
    BotCommand(command: 'faq', description: 'Как читать анализ'),
  ], scope: BotCommandScopeAllPrivateChats());

  await bot.api.setChatMenuButton(MenuButtonCommands());
}
