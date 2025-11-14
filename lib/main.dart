import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Diary',
      theme: ThemeData(
        useMaterial3: true,

        // 🔥 AppBar を白にする
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, // アイコン・文字色
          elevation: 0, // 影なしでiOSっぽく
          surfaceTintColor: Colors.white, // Material3の青っぽい影を消す
        ),

        // 🔥 Scaffold の背景を白
        scaffoldBackgroundColor: Colors.white,

        // 🔥 FilledButton を「白背景＋薄い枠」で iOSっぽく
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              const Color.fromARGB(255, 108, 178, 235),
            ),
            foregroundColor: WidgetStateProperty.all(Colors.black),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
            side: WidgetStateProperty.all(
              BorderSide(color: Colors.grey.shade300),
            ),
            elevation: WidgetStateProperty.all(0),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      home: const DiaryPage(),
    );
  }
}

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode(); // ← 追加
  Mood _selectedMood = Mood.none;
  final List<DiaryEntry> _entries = [];

  bool _isTextFieldFocused = false; // ← 追加

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _textFieldFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateText = "${today.year}/${today.month}/${today.day}";

    return Scaffold(
      backgroundColor: Colors.white, // ← これを追加！
      appBar: AppBar(title: const Text("Today's Log")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 今日の日付
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              /// 日記入力欄
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isTextFieldFocused
                        ? Colors.blue.withValues(alpha: 0.8)
                        : Colors.grey.shade400,
                    width: _isTextFieldFocused ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _textFieldFocusNode, // ← ここ大事
                  decoration: const InputDecoration(
                    hintText: '今日のひとこと…',
                    border: InputBorder.none, // ← 枠線は外側のBoxDecorationで描く
                  ),
                  maxLines: 2,
                ),
              ),

              const SizedBox(height: 16),

              /// 気分選択
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  MoodButton(
                    mood: Mood.happy,
                    selected: _selectedMood == Mood.happy,
                    onTap: () => setState(() => _selectedMood = Mood.happy),
                  ),
                  const SizedBox(width: 12),
                  MoodButton(
                    mood: Mood.neutral,
                    selected: _selectedMood == Mood.neutral,
                    onTap: () => setState(() => _selectedMood = Mood.neutral),
                  ),
                  const SizedBox(width: 12),
                  MoodButton(
                    mood: Mood.sad,
                    selected: _selectedMood == Mood.sad,
                    onTap: () => setState(() => _selectedMood = Mood.sad),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// 保存ボタン
              SaveButton(
                onPressed: () {
                  if (_controller.text.isEmpty || _selectedMood == Mood.none) {
                    return;
                  }

                  setState(() {
                    _entries.insert(
                      0,
                      DiaryEntry(
                        date: today,
                        text: _controller.text,
                        mood: _selectedMood,
                      ),
                    );
                  });

                  _controller.clear();
                  _selectedMood = Mood.none;
                },
              ),

              const SizedBox(height: 24),

              /// 最近3日分の記録
              const Text(
                "最近の記録",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];

                    // 一番新しい（先頭）の要素だけ「新規追加アニメーション」をつける
                    final isNewest = index == 0;

                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: isNewest ? 0.0 : 1.0,
                        end: 1.0,
                      ),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 12),
                            child: child,
                          ),
                        );
                      },

                      // ✅ ここを差し替え
                      child: Dismissible(
                        // それぞれのカードに一意なキーをつける
                        key: ValueKey(
                          'entry_${entry.date.toIso8601String()}_${entry.text.hashCode}',
                        ),

                        // 右→左スワイプだけで削除（iOSっぽい動き）
                        direction: DismissDirection.endToStart,

                        // スワイプ中に見える「赤い削除背景」
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delete,
                            color: Colors.red.withValues(alpha: 0.9),
                          ),
                        ),

                        // 実際にスワイプしきったときの処理
                        onDismissed: (_) {
                          setState(() {
                            _entries.remove(entry); // この entry を削除
                          });

                          // 軽くフィードバック（お好みで）
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('日記を削除しました'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },

                        // 中身はこれまで通り HoverCard + Card
                        child: HoverCard(
                          child: Card(
                            child: ListTile(
                              title: Text(entry.text),
                              subtitle: Text(
                                "${entry.date.year}/${entry.date.month}/${entry.date.day}",
                              ),
                              leading: Text(
                                moodToEmoji(entry.mood),
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mood enum
enum Mood { none, happy, neutral, sad }

/// モデルクラス
class DiaryEntry {
  final DateTime date;
  final String text;
  final Mood mood;

  DiaryEntry({required this.date, required this.text, required this.mood});
}

/// ムードボタン
class MoodButton extends StatelessWidget {
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // selected のときは 1.1倍、それ以外は 1.0倍
    final targetScale = selected ? 1.1 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        // アニメーションさせたい値（ここでは scale）
        tween: Tween<double>(begin: 1.0, end: targetScale),
        duration: const Duration(milliseconds: 150),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        // child には「中身のUI」をそのまま渡す
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(moodToEmoji(mood), style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}

/// mood → 絵文字
String moodToEmoji(Mood mood) {
  switch (mood) {
    case Mood.happy:
      return "😊";
    case Mood.neutral:
      return "😐";
    case Mood.sad:
      return "😢";
    default:
      return "…";
  }
}

class HoverCard extends StatefulWidget {
  final Widget child;
  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0, // ← 拡大率だけ指定
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class SaveButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool enabled;
  final String label;

  const SaveButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.label = '保存する',
  });

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0, // 押してる間だけ少し小さく
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack, // 戻るときに「ポフッ」とちょいバウンス
        child: FilledButton(
          // テーマは今の FilledButtonTheme がそのまま効く
          onPressed: widget.enabled ? widget.onPressed : null,
          child: Text(widget.label),
        ),
      ),
    );
  }
}
