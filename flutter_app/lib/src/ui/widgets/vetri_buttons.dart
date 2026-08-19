import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// வெற்றி TNPSC — Professional Button System
// Consistent gradient/shadow/press-animation across the whole app
// ============================================================

const _ink = Color(0xFF14213D);
const _gold = Color(0xFFC9971C);
const _verm = Color(0xFFB33A2B);
const _leaf = Color(0xFF2E7D4F);
const _leafDark = Color(0xFF1F5C38);

enum VetriButtonStyle { primary, danger, gold, outline, ghost }

/// Base pressable scale/ripple wrapper — every Vetri button uses this.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, required this.onTap});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1;
  void _set(bool down) {
    if (widget.onTap == null) return;
    setState(() => _scale = down ? 0.97 : 1);
    if (down) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Full-width primary/secondary/outline/ghost button with icon support.
class VetriButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final VetriButtonStyle style;
  final bool loading;
  final bool fullWidth;
  final double height;

  const VetriButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.style = VetriButtonStyle.primary,
    this.loading = false,
    this.fullWidth = true,
    this.height = 54,
  });

  ({List<Color> grad, Color fg, List<BoxShadow> shadow, Border? border}) get _look {
    switch (style) {
      case VetriButtonStyle.primary:
        return (
          grad: [_leaf, _leafDark],
          fg: Colors.white,
          shadow: [BoxShadow(color: _leaf.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 6))],
          border: null,
        );
      case VetriButtonStyle.danger:
        return (
          grad: [_verm, const Color(0xFF8C2A1F)],
          fg: Colors.white,
          shadow: [BoxShadow(color: _verm.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 6))],
          border: null,
        );
      case VetriButtonStyle.gold:
        return (
          grad: [_gold, const Color(0xFFA87A12)],
          fg: _ink,
          shadow: [BoxShadow(color: _gold.withOpacity(.4), blurRadius: 14, offset: const Offset(0, 6))],
          border: null,
        );
      case VetriButtonStyle.outline:
        return (
          grad: [Colors.white, Colors.white],
          fg: _leaf,
          shadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 3))],
          border: Border.all(color: _leaf, width: 1.6),
        );
      case VetriButtonStyle.ghost:
        return (
          grad: [Colors.transparent, Colors.transparent],
          fg: _ink,
          shadow: const [],
          border: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final look = _look;
    final disabled = onPressed == null || loading;
    return _Pressable(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: fullWidth ? double.infinity : null,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: style == VetriButtonStyle.ghost
              ? null
              : LinearGradient(colors: look.grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          border: look.border,
          boxShadow: disabled ? [] : look.shadow,
        ),
        child: Opacity(
          opacity: disabled && style != VetriButtonStyle.ghost ? 0.55 : 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: look.fg),
                )
              else ...[
                if (icon != null) ...[
                  Icon(icon, size: 20, color: look.fg),
                  const SizedBox(width: 9),
                ],
                Text(label,
                    style: TextStyle(
                        color: look.fg, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .2)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact chip-style choice button (subject filters, difficulty picks, etc.)
class VetriChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const VetriChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [_leaf, _leafDark]) : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE0D8C4), width: 1.4),
          boxShadow: [
            BoxShadow(
                color: (selected ? _leaf : Colors.black).withOpacity(selected ? .28 : .05),
                blurRadius: selected ? 10 : 5,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : _ink),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}

/// Circular icon-only button (send, close, back-alt, FAB-style)
class VetriIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final double size;
  const VetriIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.bg = _leaf,
    this.fg = Colors.white,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [bg, bg.withOpacity(.85)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: bg.withOpacity(.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: fg, size: size * 0.46),
      ),
    );
  }
}

/// Answer-option button for question cards / test screen (A/B/C/D)
class VetriOptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final bool? isCorrect; // null = not revealed yet
  final VoidCallback onTap;

  const VetriOptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    Color border = const Color(0xFFE0DACB);
    Color bg = Colors.white;
    Color letterBg = const Color(0xFFF1ECDD);
    Color letterFg = _ink;

    if (isCorrect != null) {
      if (isCorrect!) {
        border = _leaf; bg = const Color(0xFFEDF7F0); letterBg = _leaf; letterFg = Colors.white;
      } else if (selected) {
        border = _verm; bg = const Color(0xFFFDECEA); letterBg = _verm; letterFg = Colors.white;
      }
    } else if (selected) {
      border = _leaf; bg = const Color(0xFFEDF7F0); letterBg = _leaf; letterFg = Colors.white;
    }

    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.8),
          boxShadow: selected || isCorrect == true
              ? [BoxShadow(color: border.withOpacity(.22), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 30, height: 30,
              decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(letter,
                  style: TextStyle(color: letterFg, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 15.5, height: 1.4)),
            ),
            if (isCorrect == true) const Icon(Icons.check_circle, color: _leaf, size: 20),
            if (isCorrect == false && selected) const Icon(Icons.cancel, color: _verm, size: 20),
          ],
        ),
      ),
    );
  }
}
