/// Nine Men's Morris PRO: Free-vs-Pro comparison, real purchase, restore,
/// and tip jar. All prices come from the store — never hardcoded, never
/// placeholders. Graceful "available after store setup" when Wajiha has not
/// yet created the products in Play Console.
library;

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../audio/sound.dart';
import '../../services/iap_service.dart';
import '../../state/settings.dart';
import '../../theme/morris_themes.dart';
import '../lapidary.dart';
import '../widgets.dart';

class ProScreen extends StatefulWidget {
  final StoreService store;
  const ProScreen({super.key, required this.store});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  MorrisTheme get _t => SettingsStore.I.activeTheme;

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      Sound.I.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — the full quarry is yours!',
              style: Lapidary.body(15)),
          backgroundColor: Lapidary.basalt,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
      setState(() {});
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    Sound.I.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Lapidary.body(15)),
        backgroundColor: Lapidary.basalt,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final store = widget.store;
    return Scaffold(
      backgroundColor: t.basaltDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Lapidary.bronzeLight),
          onPressed: () {
            Sound.I.click();
            Navigator.of(context).pop();
          },
        ),
        title: Text('MORRIS PRO',
            style: Lapidary.letterpress(22, weight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: SettingsStore.I,
          builder: (_, _) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _ComparisonCard(
                    isPro: SettingsStore.I.proUnlocked, theme: t),
                const SizedBox(height: 14),
                _BuyCard(store: store, theme: t),
                const SizedBox(height: 14),
                _TipsCard(store: store, theme: t),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Free vs Pro comparison table — players see the big difference.
class _ComparisonCard extends StatelessWidget {
  final bool isPro;
  final MorrisTheme theme;
  const _ComparisonCard({required this.isPro, required this.theme});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete Nine Men\u2019s Morris', true, true),
      ('All official rules enforced', true, true),
      ('3 bot difficulties', true, true),
      ('Pass-and-play for 2', true, true),
      ('Renameable players', true, true),
      ('Music & stone sound effects', true, true),
      ('Carved-stone themes', '4', '14'),
      ('Piece styles', '3', '10'),
      ('Board accents', '2', '7'),
      ('Custom theme creator', false, true),
      ('Full statistics history', true, true),
      ('Early access to new games', false, true),
    ];
    return ParchmentPanel(
      child: Column(
        children: [
          Text('FREE vs PRO',
              style: Lapidary.letterpress(20, weight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('One purchase. Yours forever.',
              style: Lapidary.body(13,
                  color: theme.sepiaInk.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: Lapidary.letterpress(12,
                          weight: FontWeight.bold),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: Lapidary.letterpress(12,
                              weight: FontWeight.bold)
                          .copyWith(color: theme.verdigris),
                      textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                      flex: 5,
                      child: Text(r.$1, style: Lapidary.body(13))),
                  Expanded(flex: 2, child: _Cell(value: r.$2)),
                  Expanded(flex: 2, child: _Cell(value: r.$3)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.verdigris.withValues(alpha: 0.18),
                  border: Border.all(color: theme.verdigris),
                ),
                child: Text('PRO ACTIVE',
                    style: Lapidary.letterpress(14,
                            weight: FontWeight.bold)
                        .copyWith(color: theme.verdigris)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  const _Cell({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final v = value as bool;
      return Text(v ? '✓' : '—',
          style: Lapidary.body(15,
              color: v
                  ? Lapidary.verdigris
                  : Lapidary.sepiaInk.withValues(alpha: 0.4)),
          textAlign: TextAlign.center);
    }
    return Text(value as String,
        style: Lapidary.letterpress(12, weight: FontWeight.bold),
        textAlign: TextAlign.center);
  }
}

class _BuyCard extends StatelessWidget {
  final StoreService store;
  final MorrisTheme theme;
  const _BuyCard({required this.store, required this.theme});

  @override
  Widget build(BuildContext context) {
    final pro = store.proProduct;
    final isPro = SettingsStore.I.proUnlocked;
    return ParchmentPanel(
      child: Column(
        children: [
          Text('UNLOCK PRO',
              style: Lapidary.letterpress(20, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (isPro)
            Text('You already own PRO — thank you!',
                style: Lapidary.body(14), textAlign: TextAlign.center)
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Lapidary.body(14,
                  color: theme.sepiaInk.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            )
          else if (pro != null) ...[
            Text(
                pro.description.isNotEmpty
                    ? pro.description
                    : 'Unlock every carving in Nine Men\u2019s Morris, forever.',
                style: Lapidary.body(14),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => BronzeTablet(
                label: busy ? 'WORKING…' : 'GET PRO — ${pro.price}',
                fontSize: 16,
                onTap: busy
                    ? () {}
                    : () {
                        Sound.I.click();
                        store.buyPro();
                      },
              ),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: Lapidary.body(13,
                            color: const Color(0xFF9A3A2A)),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              Sound.I.click();
              store.restore();
            },
            child: Text('Restore purchases',
                style: Lapidary.body(13,
                    color: theme.verdigris)),
          ),
        ],
      ),
    );
  }
}

/// Consumable tips — pure support, with real store prices.
class _TipsCard extends StatelessWidget {
  final StoreService store;
  final MorrisTheme theme;
  const _TipsCard({required this.store, required this.theme});

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return ParchmentPanel(
      child: Column(
        children: [
          Text('TIP THE MAKER',
              style: Lapidary.letterpress(20, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Nine Men\u2019s Morris is free forever. A small tip keeps new games coming!',
            style: Lapidary.body(14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Lapidary.body(13,
                  color: theme.sepiaInk.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: Lapidary.body(13,
                    color: theme.sepiaInk.withValues(alpha: 0.6)))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _TipChip(
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                    onTap: () {
                      Sound.I.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TipChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Lapidary.basalt.withValues(alpha: 0.12),
          border: Border.all(
              color: Lapidary.bronze.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label,
            style: Lapidary.letterpress(14, weight: FontWeight.bold)),
      ),
    );
  }
}
