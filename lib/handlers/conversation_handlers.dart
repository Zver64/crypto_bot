import 'package:televerse/televerse.dart';
import 'package:televerse/plugins/conversation.dart';
import '../services/bot_state.dart';

Future<void> setThresholdHandler(Conversation conversation, Context ctx) async {
  await ctx.reply('Send me the threshold percentage (e.g., 50):');
  
  final response = await conversation.waitFor((ctx) => RegExp(r'^\d+\.?\d*$').hasMatch(ctx.text ?? ''));
  final double? newThreshold = double.tryParse(response.text ?? '');
  
  if (newThreshold != null && newThreshold > 0) {
    BotState.setThreshold(newThreshold);
    await response.reply('✅ Price threshold set to ${newThreshold.toStringAsFixed(1)}%');
  } else {
    await response.reply('Invalid percentage. Please enter a positive number.');
  }
}
