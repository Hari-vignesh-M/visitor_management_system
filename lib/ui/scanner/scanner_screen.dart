import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../routes/router_name.dart';
import '../../viewModel/base_view_model/base_view_model.dart';
import '../../viewModel/scanner_view_model/scanner_viewmodel.dart';

/// Camera view that scans a visitor QR and opens the visitor details.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  static const double _windowSize = 250;

  /// True while the details screen is open on top of the scanner.
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  /// Release the camera when the app goes to the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission || _isNavigating) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        unawaited(_controller.stop());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final vm = context.read<ScannerViewModel>();
    if (_isNavigating || vm.isProcessing || capture.barcodes.isEmpty) return;

    final visitor = await vm.onScan(capture.barcodes.first.rawValue);
    if (!mounted) return;

    // Invalid / unknown QR: the status panel shows the error and the
    // camera keeps running for the next scan.
    if (visitor == null) return;

    _isNavigating = true;
    await _controller.stop();
    if (!mounted) return;
    await context.push(RouteName.visitorDetailsPath(visitor.id));

    // Back from details: ready for the next visitor.
    if (!mounted) return;
    vm.reset();
    _isNavigating = false;
    unawaited(_controller.start());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Visitor QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Flashlight',
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: _controller.toggleTorch,
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = Rect.fromCenter(
            center: constraints.biggest.center(Offset.zero),
            width: _windowSize,
            height: _windowSize,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanWindow,
                onDetect: _onDetect,
                errorBuilder: (context, error) =>
                    _ScannerError(error: error, onRetry: _controller.start),
              ),
              IgnorePointer(
                child: CustomPaint(painter: _ScanWindowPainter(scanWindow)),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 32,
                child: SafeArea(child: _StatusPanel()),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Message under the scan area: hint, "looking up...", or the last error.
class _StatusPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScannerViewModel>();

    final (IconData icon, String text, Color color) = switch (vm.state) {
      ViewState.busy => (Icons.search, 'Looking up visitor...', Colors.white),
      ViewState.error => (Icons.error_outline, vm.errorMsg, Colors.redAccent),
      _ => (Icons.qr_code_2, 'Place the visitor QR code inside the frame', Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (vm.isProcessing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}

/// Shown instead of the camera preview when the camera cannot start.
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final message = isPermission
        ? 'Camera permission denied.\nAllow camera access for this app in '
            'your phone Settings to scan visitor QR codes.'
        : 'Unable to start the camera.\n${error.errorDetails?.message ?? ''}';

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPermission ? Icons.no_photography_outlined : Icons.error_outline,
                color: Colors.white70,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dims everything outside the scan window and draws its border.
class _ScanWindowPainter extends CustomPainter {
  _ScanWindowPainter(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(window, const Radius.circular(16));
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(frame)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlay, Paint()..color = Colors.black54);
    canvas.drawRRect(
      frame,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_ScanWindowPainter oldDelegate) =>
      oldDelegate.window != window;
}
