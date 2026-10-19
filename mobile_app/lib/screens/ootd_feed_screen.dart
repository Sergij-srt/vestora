import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class OotdPost {
  final String id;
  final String authorName;
  final String authorHandle;
  final String authorAvatar;
  final String occasion;
  final String weatherTag;
  final String imageUrl;
  final String caption;
  final double styleScore;
  final List<String> taggedItems;
  int likesCount;
  bool isLiked;

  OotdPost({
    required this.id,
    required this.authorName,
    required this.authorHandle,
    required this.authorAvatar,
    required this.occasion,
    required this.weatherTag,
    required this.imageUrl,
    required this.caption,
    required this.styleScore,
    required this.taggedItems,
    required this.likesCount,
    this.isLiked = false,
  });
}

class OotdFeedScreen extends StatefulWidget {
  const OotdFeedScreen({super.key});

  @override
  State<OotdFeedScreen> createState() => _OotdFeedScreenState();
}

class _OotdFeedScreenState extends State<OotdFeedScreen> {
  String _activeFilter = 'Усі';

  final List<OotdPost> _posts = [
    OotdPost(
      id: '1',
      authorName: 'Олена Коваль',
      authorHandle: '@olena_capsule',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      occasion: 'Офіс / Діловий 💼',
      weatherTag: '+16°C · Хмарно ⛅',
      imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800',
      caption: 'Сьогодні зібрала діловий монохром з перевіреним блейзером Zara та вовняними палаццо. Cost-per-wear жакета вже менше 90 ₴!',
      styleScore: 9.6,
      taggedItems: ['Zara Blazer Оверсайз', 'Massimo Dutti Палаццо', 'Acne Studios Шарф'],
      likesCount: 142,
    ),
    OotdPost(
      id: '2',
      authorName: 'Дарія Стиліст',
      authorHandle: '@daria_style_kyiv',
      authorAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      occasion: 'Кав\'ярня / Прогулянка ☕',
      weatherTag: '+18°C · Сонячно ☀️',
      imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800',
      caption: 'Дотрималась "правила трьох кольорів": карамель, молочний та глибокий синій. Легкість та мінімалістичний комфорт.',
      styleScore: 9.8,
      taggedItems: ['COS Бавовняна сорочка', 'Levi\'s 501 Джинси', 'Celine Тріоф Окуляри'],
      likesCount: 289,
    ),
    OotdPost(
      id: '3',
      authorName: 'Марія В.',
      authorHandle: '@maria_minimal',
      authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      occasion: 'Вечір / Театр ✨',
      weatherTag: '+12°C · Прохолодно 💨',
      imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=800',
      caption: 'Дощовий вечір вимагає класичного тренча. Додала шовкову хустку та шкіряні лофери.',
      styleScore: 9.4,
      taggedItems: ['Mango Тренч Бежевий', 'Шовкова сукня міді', 'Massimo Dutti Лофери'],
      likesCount: 97,
    ),
  ];

  void _showCrowdStylingSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        const guestLink = 'https://vestora.app/guest/olena-k?token=vst_71e49d';
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people_alt_outlined, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crowd-Styling Vestora',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Відкрийте безпечний доступ до шафи',
                          style: TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Надішліть це посилання подрузі або персональному стилісту. Вони зможуть збирати для вас капсульні образи з ваших речей, не маючи доступу до ваших цін та особистих даних.',
                style: TextStyle(fontSize: 13, color: AppTheme.secondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        guestLink,
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20, color: AppTheme.primary),
                      tooltip: 'Скопіювати лінк',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: guestLink));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Гостьове посилання скопійовано! Надішліть його у Telegram або Instagram.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: guestLink));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Гостьове посилання скопійовано!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Скопіювати та поділитися'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['Усі', 'Офіс 💼', 'Кав\'ярня ☕', 'Вечірні ✨'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('OOTD & Спільнота'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppTheme.primary),
            tooltip: 'Запросити стиліста (Crowd-Styling)',
            onPressed: _showCrowdStylingSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Crowd styling invite banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.group_rounded, color: Color(0xFF92400E)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Шукаєте погляд збоку на свій стиль?',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF78350F)),
                      ),
                      Text(
                        'Запросіть подругу або стиліста зібрати для вас аутфіт.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showCrowdStylingSheet,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF78350F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Запросити', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: filters.map((f) {
                final isSel = f == _activeFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.white : AppTheme.primary)),
                    selected: isSel,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.background,
                    onSelected: (val) {
                      if (val) setState(() => _activeFilter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Posts Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return _buildPostCard(post);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(OotdPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(post.authorAvatar),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(post.authorHandle, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${post.styleScore}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Photo with Tag Overlay
          Stack(
            children: [
              ClipRRect(
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  height: 340,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${post.occasion} · ${post.weatherTag}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // Tagged items pills
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: post.taggedItems.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 10, color: AppTheme.muted),
                      const SizedBox(width: 4),
                      Text(tag, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Caption & Likes
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.caption,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.secondary, height: 1.35),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          post.isLiked = !post.isLiked;
                          post.likesCount += post.isLiked ? 1 : -1;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: post.isLiked ? Colors.red : AppTheme.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likesCount}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded, size: 20, color: AppTheme.muted),
                      tooltip: 'Зберегти в капсулу',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Образ збережено до натхнення!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
