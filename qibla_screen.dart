import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/app_state.dart';
import 'theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  List<double>? _gravity;
  List<double>? _magnet;
  double? _heading; // degrees from magnetic north
  bool _sensorError = false;

  @override
  void initState() {
    super.initState();
    try {
      _accSub = accelerometerEventStream().listen(
        (e) {
          _gravity = _lowPass([e.x, e.y, e.z], _gravity);
          _update();
        },
        onError: (_) => setState(() => _sensorError = true),
        cancelOnError: true,
      );
      _magSub = magnetometerEventStream().listen(
        (e) {
          _magnet = _lowPass([e.x, e.y, e.z], _magnet);
          _update();
        },
        onError: (_) => setState(() => _sensorError = true),
        cancelOnError: true,
      );
    } catch (_) {
      _sensorError = true;
    }
  }

  List<double> _lowPass(List<double> input, List<double>? prev) {
    if (prev == null) return input;
    const a = 0.15;
    return [for (var i = 0; i < 3; i++) prev[i] + a * (input[i] - prev[i])];
  }

  /// Tilt-compensated heading, the same maths as Android's
  /// SensorManager.getRotationMatrix and getOrientation.
  void _update() {
    final g = _gravity;
    final m = _magnet;
    if (g == null || m == null || !mounted) return;
    final ax = g[0], ay = g[1], az = g[2];
    final ex = m[0], ey = m[1], ez = m[2];
    var hx = ey * az - ez * ay;
    var hy = ez * ax - ex * az;
    var hz = ex * ay - ey * ax;
    final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (normH < 0.1) return;
    hx /= normH;
    hy /= normH;
    hz /= normH;
    final normA = math.sqrt(ax * ax + ay * ay + az * az);
    if (normA == 0) return;
    final gx = ax / normA, gy = ay / normA, gz = az / normA;
    final my = gz * hx - gx * hz;
    final azimuth = math.atan2(hy, my) * 180 / math.pi;
    setState(() => _heading = (azimuth + 360) % 360);
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  String _compassPoint(double deg) {
    const points = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return points[((deg + 22.5) % 360 ~/ 45)];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final bearing = s.qiblaBearing;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla')),
      body: bearing == null
          ? const Center(child: Text('Set your location first.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('${bearing.toStringAsFixed(0)}° ${_compassPoint(bearing)}',
                    style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                Text('clockwise from north, from ${s.settings.place.isEmpty ? 'your location' : s.settings.place}',
                    style: text.bodyMedium),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 1,
                  child: _Dial(bearing: bearing, heading: _heading),
                ),
                const SizedBox(height: 16),
                if (_heading != null) ...[
                  _alignmentHint(context, bearing, _heading!),
                  const SizedBox(height: 12),
                ],
                Panel(
                  margin: EdgeInsets.zero,
                  child: Text(
                    _sensorError || _heading == null
                        ? 'This phone’s compass isn’t available here. Open your phone’s own compass app and face ${bearing.toStringAsFixed(0)}°.'
                        : 'Hold the phone flat, away from metal and magnets. If the needle seems wrong, move the phone in a figure of eight to calibrate. The live compass points to magnetic north, which can differ from true north by a few degrees.',
                    style: text.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _alignmentHint(BuildContext context, double bearing, double heading) {
    var diff = (bearing - heading + 540) % 360 - 180; // -180..180
    final text = Theme.of(context).textTheme;
    final aligned = diff.abs() < 5;
    final msg = aligned
        ? 'You are facing the Qibla'
        : diff > 0
            ? 'Turn right ${diff.abs().round()}°'
            : 'Turn left ${diff.abs().round()}°';
    return Text(msg,
        textAlign: TextAlign.center,
        style: text.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: aligned ? Theme.of(context).colorScheme.primary : null));
  }
}

class _Dial extends StatelessWidget {
  final double bearing;
  final double? heading;
  const _Dial({required this.bearing, required this.heading});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rotation = heading == null ? 0.0 : -heading! * math.pi / 180;
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        painter: _DialPainter(
          bearing: bearing,
          ring: scheme.onSurface.withValues(alpha: 0.2),
          label: scheme.onSurface,
          accent: scheme.primary,
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double bearing;
  final Color ring;
  final Color label;
  final Color accent;
  _DialPainter({required this.bearing, required this.ring, required this.label, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 8;
    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r, ringPaint);
    for (var i = 0; i < 72; i++) {
      final a = i * 5 * math.pi / 180;
      final len = i % 18 == 0 ? 16.0 : (i % 2 == 0 ? 8.0 : 4.0);
      final p1 = c + Offset(math.sin(a), -math.cos(a)) * r;
      final p2 = c + Offset(math.sin(a), -math.cos(a)) * (r - len);
      canvas.drawLine(p1, p2, ringPaint);
    }
    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: i == 0 ? accent : label, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = c + Offset(math.sin(a), -math.cos(a)) * (r - 34);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
    final qa = bearing * math.pi / 180;
    final dir = Offset(math.sin(qa), -math.cos(qa));
    final needle = Paint()
      ..color = accent
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + dir * (r - 50), needle);
    canvas.drawCircle(c + dir * (r - 50), 14, Paint()..color = accent);
    final kaaba = Paint()..color = Colors.white;
    final tip = c + dir * (r - 50);
    canvas.drawRect(Rect.fromCenter(center: tip, width: 12, height: 12), kaaba);
    canvas.drawCircle(c, 6, Paint()..color = label);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.bearing != bearing || old.ring != ring || old.accent != accent || old.label != label;
}
