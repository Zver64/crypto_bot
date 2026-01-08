import 'package:televerse/televerse.dart';
import 'package:televerse/plugins/conversation.dart';
import '../services/bot_state.dart';
import '../utils/common.dart';

Future<void> setThresholdHandler(Conversation conversation, Context ctx) async {
  await ctx.reply('Send me the min cap threshold (e.g., 200):');
  
  final minCapResponse = await conversation.waitFor((ctx) => RegExp(r'^\d+$').hasMatch(ctx.text ?? ''));
  final int? minCap = int.tryParse(minCapResponse.text ?? '');
  
  if (minCap == null || minCap <= 0) {
    await minCapResponse.reply('Invalid min cap. Please enter a positive integer.');
    return;
  }

  await minCapResponse.reply('Send me the max cap threshold (e.g., 10):');
  
  final maxCapResponse = await conversation.waitFor((ctx) => RegExp(r'^\d+$').hasMatch(ctx.text ?? ''));
  final int? maxCap = int.tryParse(maxCapResponse.text ?? '');
  
  if (maxCap != null && maxCap > 0) {
    BotState.setThreshold(minCap, maxCap);
    await maxCapResponse.reply('''
🎯 *Thresholds Updated Successfully!*

📊 *Current Settings:*
• Min Cap Threshold: $minCap%
• Max Cap Threshold: $maxCap%

📈 *Example Calculations:*
• \$50M market cap → ${volatilityFromMcap(50000000, smallVol: minCap.toDouble(), largeVol: maxCap.toDouble()).toStringAsFixed(1)}% threshold
• \$100M market cap → ${volatilityFromMcap(100000000, smallVol: minCap.toDouble(), largeVol: maxCap.toDouble()).toStringAsFixed(1)}% threshold  
• \$500M market cap → ${volatilityFromMcap(500000000, smallVol: minCap.toDouble(), largeVol: maxCap.toDouble()).toStringAsFixed(1)}% threshold

✅ *Bot will now alert when coins exceed their calculated thresholds!*
''');
  } else {
    await maxCapResponse.reply('Invalid max cap. Please enter a positive integer.');
  }
}
