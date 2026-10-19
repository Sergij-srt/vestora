import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showVestoraBrandStory(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Brand Header with Monogram
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF121214), Color(0xFF27272A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'V',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'VESTORA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your Wardrobe, Elevated',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'ЩО ПРИХОВАНО В НАЗВІ VESTORA?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 14),

            // 3 Pillars
            _buildPillarTile(
              tag: 'VESTIS',
              origin: 'латинською «одяг»',
              description: 'Справжній сенс вашого стилю. Всі ваші речі нарешті оцифровані та зібрані в одному красивому просторі.',
              icon: Icons.checkroom_rounded,
              accentColor: const Color(0xFF38BDF8),
            ),
            const SizedBox(height: 10),

            _buildPillarTile(
              tag: 'AURA',
              origin: 'внутрішня впевненість',
              description: 'Спокій щоранку. AI підбирає готовий образ під реальну погоду та ваш день — без паніки «нічого вдягти».',
              icon: Icons.auto_awesome_rounded,
              accentColor: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 10),

            _buildPillarTile(
              tag: 'STORE',
              origin: 'розумне володіння',
              description: 'Свідомий гардероб як актив. Оцінка окупності речей (Cost-Per-Wear) та захист від імпульсивних покупок-дублікатів.',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 20),

            // Manifesto Quote Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text(
                '«Носіть те, що маєте. Купуйте лише те, що дійсно має значення.»',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Повернутися до шафи'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildPillarTile({
  required String tag,
  required String origin,
  required String description,
  required IconData icon,
  required Color accentColor,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    tag,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($origin)',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3F3F46),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
