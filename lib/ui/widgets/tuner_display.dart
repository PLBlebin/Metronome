import 'package:flutter/material.dart';
import '../../models/note.dart';

class TunerDisplay extends StatelessWidget {
  final Note? detectedNote;
  final double? detectedCents;
  final bool isListening;

  static const double kInTuneThreshold = 5.0;

  const TunerDisplay({
    super.key,
    this.detectedNote,
    this.detectedCents,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isInTune = detectedCents != null && detectedCents!.abs() <= kInTuneThreshold;

    Color noteColor;
    if (detectedNote == null) {
      noteColor = colors.onSurface.withValues(alpha: 0.3);
    } else if (isInTune) {
      noteColor = Colors.green;
    } else if (detectedCents != null && detectedCents! < 0) {
      noteColor = Colors.blue; // flat
    } else {
      noteColor = Colors.orange; // sharp
    }

    return Column(
      children: [
        Text(
          detectedNote?.displayName ?? '--',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: noteColor,
          ),
        ),
        const SizedBox(height: 8),
        // Cents indicator bar
        SizedBox(
          width: 280,
          height: 40,
          child: CustomPaint(
            painter: _CentsBarPainter(cents: detectedCents),
          ),
        ),
        const SizedBox(height: 8),
        // Fixed height to prevent layout shift when content changes
        SizedBox(
          height: 28,
          child: Text(
            detectedCents != null
                ? '${detectedCents! >= 0 ? '+' : ''}${detectedCents!.toStringAsFixed(0)} cents'
                : isListening ? '等待检测...' : '点击开始监听',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _CentsBarPainter extends CustomPainter {
  final double? cents;

  _CentsBarPainter({this.cents});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(20, centerY),
      Offset(size.width - 20, centerY),
      trackPaint,
    );

    // In-tune zone highlight
    final inTunePaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(centerX - 20, centerY),
      Offset(centerX + 20, centerY),
      inTunePaint,
    );

    // Center tick
    final tickPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(centerX, centerY - 12),
      Offset(centerX, centerY + 12),
      tickPaint,
    );

    // Indicator
    if (cents != null) {
      final normalized = (cents! / 50.0).clamp(-1.0, 1.0);
      final x = centerX + normalized * (size.width / 2 - 30);

      final color = cents!.abs() <= 5.0
          ? Colors.green
          : (cents! < 0 ? Colors.blue : Colors.orange);
      final indicatorPaint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, centerY - 16),
        Offset(x, centerY + 16),
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CentsBarPainter old) => old.cents != cents;
}