import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Absensi"),
        actions: [
          // PERBAIKAN 1: Menggunakan ValueListenableBuilder langsung ke controller
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              // state.torchState tersedia langsung di sini
              return IconButton(
                icon: Icon(state.torchState == TorchState.off 
                    ? Icons.flash_off 
                    : Icons.flash_on),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          // PERBAIKAN 2: Menggunakan ValueListenableBuilder untuk switch camera
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              // state.cameraDirection tersedia langsung di sini
              return IconButton(
                icon: Icon(state.cameraDirection == CameraFacing.front 
                    ? Icons.camera_front 
                    : Icons.camera_rear),
                onPressed: () => controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              final String code = barcode.rawValue!;
              // Stop kamera dulu sebelum navigasi
              controller.stop(); 
              if (mounted) {
                Navigator.pop(context, code);
              }
              break;
            }
          }
        },
        overlayBuilder: (context, constraints) {
          return Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).colorScheme.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }
    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength > borderWidthSize / 2 ? borderWidthSize / 2 : borderLength;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutSize / 2 + borderOffset,
      rect.top + height / 2 - mCutOutSize / 2 + borderOffset + cutOutBottomOffset,
      mCutOutSize - borderOffset * 2,
      mCutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final borderRect = RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius));

    canvas
      ..drawPath(
        Path()
          ..moveTo(borderRect.left, borderRect.top + mBorderLength)
          ..lineTo(borderRect.left, borderRect.top)
          ..lineTo(borderRect.left + mBorderLength, borderRect.top),
        borderPaint,
      )
      ..drawPath(
        Path()
          ..moveTo(borderRect.left, borderRect.bottom - mBorderLength)
          ..lineTo(borderRect.left, borderRect.bottom)
          ..lineTo(borderRect.left + mBorderLength, borderRect.bottom),
        borderPaint,
      )
      ..drawPath(
        Path()
          ..moveTo(borderRect.right - mBorderLength, borderRect.top)
          ..lineTo(borderRect.right, borderRect.top)
          ..lineTo(borderRect.right, borderRect.top + mBorderLength),
        borderPaint,
      )
      ..drawPath(
        Path()
          ..moveTo(borderRect.right - mBorderLength, borderRect.bottom)
          ..lineTo(borderRect.right, borderRect.bottom)
          ..lineTo(borderRect.right, borderRect.bottom - mBorderLength),
        borderPaint,
      );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}