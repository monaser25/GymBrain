import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/duration_formatter.dart';

/// A lightweight widget that ticks every second and displays the elapsed
/// duration since [startTime], formatted for the current locale.
///
/// Only this widget rebuilds each second — the parent tree is untouched.
class LiveTimerText extends StatefulWidget {
  final DateTime startTime;
  final TextStyle? style;

  const LiveTimerText({
    super.key,
    required this.startTime,
    this.style,
  });

  @override
  State<LiveTimerText> createState() => _LiveTimerTextState();
}

class _LiveTimerTextState extends State<LiveTimerText> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    // Calculate immediately so the first frame is correct (no zero-flicker).
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Text(
      formatLocalizedDuration(_elapsed, locale),
      style: widget.style,
    );
  }
}
