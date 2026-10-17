import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ResultScreen extends StatefulWidget {
  final double billTotal;
  final double tipPercentage;
  final int numberOfPeople;

  const ResultScreen({
    super.key,
    required this.billTotal,
    required this.tipPercentage,
    required this.numberOfPeople,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isGeneratingImage = false;

  // Calculations
  double get tipAmount => widget.billTotal * widget.tipPercentage / 100;
  double get grandTotal => widget.billTotal + tipAmount;
  double get perPersonAmount => grandTotal / widget.numberOfPeople;

  String get _textSummary => '''
🧾 Splitzo Bill Summary
───────────────────────────
• Bill Amount: \$${widget.billTotal.toStringAsFixed(2)}
• Tip (${widget.tipPercentage.round()}%): \$${tipAmount.toStringAsFixed(2)}
• Total with Tip: \$${grandTotal.toStringAsFixed(2)}
• Split Between: ${widget.numberOfPeople} ${widget.numberOfPeople == 1 ? 'person' : 'people'}
───────────────────────────
💰 Each Person Pays: \$${perPersonAmount.toStringAsFixed(2)}

Split with Splitzo''';

  Future<void> _shareText() async {
    final box = context.findRenderObject() as RenderBox?;
    final originRect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    await SharePlus.instance.share(
      ShareParams(
        text: _textSummary,
        subject: 'Splitzo Bill Summary',
        sharePositionOrigin: originRect,
      ),
    );
  }

  Future<void> _shareReceiptImage() async {
    if (_isGeneratingImage) return;

    // Get originRect before async calls
    final box = context.findRenderObject() as RenderBox?;
    final originRect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    setState(() {
      _isGeneratingImage = true;
    });

    try {
      // 1. Attendre un court instant pour s'assurer que le frame est complètement rendu
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary = _receiptKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Impossible de capturer le reçu.');
      }

      // 2. Capture en haute résolution (pixelRatio 3.0 pour une netteté cristalline)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Échec de conversion de l\'image.');
      }

      final pngBytes = byteData.buffer.asUint8List();

      // 3. Enregistrer temporairement dans le cache de l'appareil
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/splitzo_receipt_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      // 4. Partager le fichier image avec SharePlus
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '🧾 Here is our bill split summary! Each person pays \$${perPersonAmount.toStringAsFixed(2)}.\nSplit with Splitzo.',
          subject: 'Splitzo Bill Summary',
          sharePositionOrigin: originRect,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating receipt image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }

  void _showShareOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryTeal = Color(0xFF1EA896);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF162523) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poignée supérieure (Handle bar)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: primaryTeal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Bill Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Choose how you want to share with friends',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Option 1 : Partage Image / Reçu (Recommandé)
                Material(
                  color: primaryTeal.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _shareReceiptImage();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryTeal,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.image_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Share as Image',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF133E38),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryTeal,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'BEST',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Stunning digital receipt card screenshot',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF4A6B65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2 : Partage Texte
                Material(
                  color: isDark ? const Color(0xFF1E2D2B) : const Color(0xFFF3F7F6),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _shareText();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A3F3C)
                                  : const Color(0xFFE2EBE8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.text_snippet_rounded,
                              color: isDark ? Colors.white70 : Colors.black87,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Share as Text',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF133E38),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Quick formatted message for chat apps',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Splitzo Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _showShareOptions(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reçu numérique capturable en image
              RepaintBoundary(
                key: _receiptKey,
                child: _buildReceiptCard(context, isDark),
              ),

              const SizedBox(height: 24),

              // Bouton principal de partage avec options
              FilledButton.icon(
                onPressed: _isGeneratingImage
                    ? null
                    : () => _showShareOptions(context),
                icon: _isGeneratingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(
                  _isGeneratingImage
                      ? 'Generating Receipt...'
                      : 'Share Summary',
                ),
              ),
              const SizedBox(height: 12),

              // Bouton direct pour partager l'image
              OutlinedButton.icon(
                onPressed: _isGeneratingImage
                    ? null
                    : () => _shareReceiptImage(),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Share as Receipt Image'),
              ),
              const SizedBox(height: 12),

              // Bouton Nouveau Calcul
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('New Calculation'),
              ),
              const SizedBox(height: 16),

              // Slogan
              Center(
                child: Text(
                  'Split the bill, not the friendship.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryTeal = Color(0xFF1EA896);

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172422) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? const Color(0xFF263D39)
              : const Color(0xFFE0ECE8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de reçu avec logo Splitzo & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: primaryTeal,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SPLITZO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: primaryTeal,
                        ),
                      ),
                      Text(
                        'Bill Receipt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF223532)
                      : const Color(0xFFEEF5F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF335850),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Carte Hero : Montant par personne
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF0F5A50), Color(0xFF133E38)]
                    : const [Color(0xFF00796B), Color(0xFF004D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const ui.Color.fromARGB(255, 215, 131, 131).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'EACH PERSON PAYS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '\$${perPersonAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.group_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Split equally among ${widget.numberOfPeople} ${widget.numberOfPeople == 1 ? 'person' : 'people'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Ligne en pointillés façon ticket de caisse
          _buildDashedLine(isDark ? const Color(0xFF334F4A) : const Color(0xFFD4E3DF)),

          const SizedBox(height: 20),

          // Détails du calcul (Breakdown)
          _buildBreakdownRow(
            context,
            label: 'Bill Subtotal',
            value: '\$${widget.billTotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            context,
            label: 'Tip (${widget.tipPercentage.round()}%)',
            value: '+\$${tipAmount.toStringAsFixed(2)}',
            valueColor: primaryTeal,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            context,
            label: 'Total with Tip',
            value: '\$${grandTotal.toStringAsFixed(2)}',
            isEmphasized: true,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            context,
            label: 'Total People',
            value: '${widget.numberOfPeople}',
          ),

          const SizedBox(height: 18),
          _buildDashedLine(isDark ? const Color(0xFF334F4A) : const Color(0xFFD4E3DF)),
          const SizedBox(height: 14),

          // Pied de page du reçu
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 15,
                color: isDark ? Colors.white54 : const Color(0xFF5B7D76),
              ),
              const SizedBox(width: 6),
              Text(
                'Calculated & Verified with Splitzo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white54 : const Color(0xFF5B7D76),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1.2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isEmphasized = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isEmphasized ? 15 : 14,
            fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
            color: isEmphasized
                ? (isDark ? Colors.white : const Color(0xFF133E38))
                : (isDark ? Colors.white70 : const Color(0xFF4A6B65)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isEmphasized ? 17 : 14,
            fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ??
                (isEmphasized
                    ? (isDark ? Colors.white : const Color(0xFF133E38))
                    : (isDark ? Colors.white : Colors.black87)),
          ),
        ),
      ],
    );
  }
}
