import 'package:flutter/material.dart';

// ------------------ SOLID PANEL ------------------

class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1026).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}


// ------------------ GLASS CARD ------------------

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  // ------------------ ICON BUTTON ------------------

  class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
  return GestureDetector(
  onTap: onTap,
  child: Container(
  width: 44,
  height: 44,
  decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.12),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
  ),
  child: Icon(icon, color: Colors.white),
  ),
  );
  }
  }

// ------------------ STARS ------------------

  class StarFieldPainter extends CustomPainter {
  const StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
  final rnd = Random(11);
  final paint = Paint()..style = PaintingStyle.fill;

  for (int i = 0; i < 190; i++) {
  final dx = rnd.nextDouble() * size.width;
  final dy = rnd.nextDouble() * size.height;

  final r = rnd.nextDouble() * 1.4 + 0.4;
  final alpha = (rnd.nextDouble() * 0.55 + 0.12);

  paint.color = Colors.white.withValues(alpha: alpha);
  canvas.drawCircle(Offset(dx, dy), r, paint);
  }

  for (int i = 0; i < 16; i++) {
  final dx = rnd.nextDouble() * size.width;
  final dy = rnd.nextDouble() * size.height;
  final r = rnd.nextDouble() * 2.0 + 1.2;

  paint.color = Colors.white.withValues(alpha: 0.55);
  canvas.drawCircle(Offset(dx, dy), r, paint);
  }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}