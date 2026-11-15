import 'package:flutter/material.dart';

/// Window width from which screens switch to their web layout. Matches the
/// home screen's sidebar breakpoint, so mobile and narrow windows never change.
const double kWebBreakpoint = 900;

bool isWideWeb(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWebBreakpoint;

/// Centers [child] and caps its width so content never stretches edge to edge.
class WebConstrained extends StatelessWidget {
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const WebConstrained({
    super.key,
    required this.child,
    this.maxWidth = 1040,
    this.padding = const EdgeInsets.symmetric(horizontal: 32),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Page title block used at the top of every wide screen: a tinted icon tile,
/// the title and one line saying what the page is for.
class WebPageHeader extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;

  const WebPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.3)),
          ),
          child: icon,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A scrolling, width-capped page with an optional [header] above [child].
class WebScrollPage extends StatelessWidget {
  final Widget? header;
  final Widget child;
  final double maxWidth;

  const WebScrollPage({
    super.key,
    required this.child,
    this.header,
    this.maxWidth = 1040,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: WebConstrained(
          maxWidth: maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null) ...[header!, const SizedBox(height: 28)],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// The app's green gradient banner (same colors the mobile headers use).
BoxDecoration webHeroDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    gradient: LinearGradient(
      colors: isDark
          ? [theme.colorScheme.secondary, const Color(0xFF145A45)]
          : [theme.colorScheme.primary, theme.colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
  );
}

/// Centers an admin list screen and caps its width on wide windows. On narrow
/// windows [child] is returned untouched.
Widget adminCentered(
  BuildContext context,
  Widget child, {
  double maxWidth = 900,
}) {
  if (!isWideWeb(context)) return child;
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Admin "compose and manage" screen. On wide windows the [form] sits in a
/// fixed left pane and the [list] fills the right pane, each scrolling on its
/// own, so publishing never pushes the existing items off screen. On narrow
/// windows they stack in one scrolling column, as before.
class AdminSplitPage extends StatefulWidget {
  final Widget form;
  final Widget list;

  const AdminSplitPage({super.key, required this.form, required this.list});

  @override
  State<AdminSplitPage> createState() => _AdminSplitPageState();
}

class _AdminSplitPageState extends State<AdminSplitPage> {
  final _formScroll = ScrollController();
  final _listScroll = ScrollController();

  @override
  void dispose() {
    _formScroll.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isWideWeb(context)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [widget.form, const SizedBox(height: 24), widget.list],
        ),
      );
    }

    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 480,
          child: Scrollbar(
            controller: _formScroll,
            child: SingleChildScrollView(
              controller: _formScroll,
              padding: const EdgeInsets.fromLTRB(28, 28, 20, 28),
              child: widget.form,
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        Expanded(
          child: Scrollbar(
            controller: _listScroll,
            child: SingleChildScrollView(
              controller: _listScroll,
              padding: const EdgeInsets.all(28),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: widget.list,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
