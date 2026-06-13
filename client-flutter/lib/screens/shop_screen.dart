import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPage,
      appBar: AppBar(
        backgroundColor: context.bgHeader,
        foregroundColor: Colors.white,
        title: const Text('Shop', style: TextStyle(
          color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18,
        )),
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _BalanceCard(coins: state.coins),
            const SizedBox(height: 20),
            _sectionLabel(context, 'COIN PACKS'),
            _PackCard(name: 'Starter Pack',  amount: '500 Coins',    price: r'$0.99', accent: AppColors.green),
            _PackCard(name: 'Popular Pack',  amount: '2,000 Coins',  price: r'$3.99', accent: AppColors.blue),
            _PackCard(name: 'Value Pack',    amount: '5,500 Coins',  price: r'$7.99', accent: AppColors.yellow),
            _PackCard(name: 'Mega Pack',     amount: '15,000 Coins', price: r'$19.99',accent: AppColors.red),
            const SizedBox(height: 8),
            _sectionLabel(context, 'FREE COINS'),
            _FreeCard(
              title: '📺  Watch an Ad',
              desc: 'Earn 50 coins per rewarded video',
              accent: AppColors.green,
              buttonLabel: '+50',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ads — coming soon')),
                );
              },
            ),
            const SizedBox(height: 10),
            _FreeCard(
              title: '🎁  Daily Bonus',
              desc: 'Come back every day for free coins',
              accent: AppColors.yellow,
              buttonLabel: 'Claim',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Daily bonus — coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(label, style: TextStyle(
        color: context.txtMuted, fontSize: 10, fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      )),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int coins;
  const _BalanceCard({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('YOUR BALANCE', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold,
            color: Colors.brown.shade800, letterSpacing: 1.2,
          )),
          const SizedBox(height: 4),
          Text('$coins', style: const TextStyle(
            fontSize: 40, color: AppColors.yellow, fontWeight: FontWeight.bold,
          )),
          Text('◈ Coins', style: TextStyle(
            fontSize: 14, color: Colors.brown.shade700,
          )),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final String name;
  final String amount;
  final String price;
  final Color accent;

  const _PackCard({
    required this.name, required this.amount, required this.price, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.strokeCard),
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(
                  color: context.txtPrimary, fontSize: 15, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 2),
                Text(amount, style: const TextStyle(
                  color: AppColors.yellow, fontSize: 12,
                )),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('In-app purchases — coming soon')),
              );
            },
            child: Text(price, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _FreeCard extends StatelessWidget {
  final String title;
  final String desc;
  final Color accent;
  final String buttonLabel;
  final VoidCallback onTap;

  const _FreeCard({
    required this.title, required this.desc, required this.accent,
    required this.buttonLabel, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.strokeCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  color: accent, fontSize: 15, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(
                  color: context.txtMuted, fontSize: 12,
                )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onTap,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
