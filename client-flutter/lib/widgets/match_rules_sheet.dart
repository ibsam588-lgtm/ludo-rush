import 'package:flutter/material.dart';
import '../data/economy.dart';

List<String> rulesForMode(String mode) => mode == 'snakes_ladders'
    ? const [
        'Start on square 1. Tap the dice; your token moves automatically after the roll.',
        'Land at a ladder’s foot to climb; a snake’s head sends you down.',
        'Reach square 100 with an exact roll to win. An overshoot passes your turn.',
        'A six moves you six squares. There is no extra roll in Snakes & Ladders.',
      ]
    : [
        'Roll a six to bring a token out of the yard. Tap a highlighted token to move.',
        'A six or a capture earns another roll. If no token can move, your turn passes.',
        'Land on an opponent to send it home. Star squares are safe; stacked tokens do not block movement.',
        'Bring all four tokens home with exact rolls to win. No three-sixes penalty.',
        if (mode.startsWith('rush'))
          'Online Rush turns last 15 seconds; the board and winning rules are the same.',
      ];

Future<bool> showMatchRules(BuildContext context, String mode) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  mode == 'snakes_ladders'
                      ? 'Snakes & Ladders rules'
                      : 'Ludo rules',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              for (final rule in rulesForMode(mode))
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('•  $rule')),
              const Divider(),
              const Text(
                  'Free entry • Online win +${GameEconomy.onlineWinCoins} coins • Online finish +${GameEconomy.onlineFinishCoins} coins.\nLocal and bot matches are practice: no coins, rating or win unlocks. Leaving early earns no coins. Cosmetics never change the odds.'),
              const SizedBox(height: 18),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Got it — start match')),
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Back')),
            ]),
      )),
    ) ??
    false;
