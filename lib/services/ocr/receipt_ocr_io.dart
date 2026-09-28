import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'receipt_ocr.dart';

class MlKitReceiptOcrService implements ReceiptOcrService {
  const MlKitReceiptOcrService();

  @override
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<ParsedReceipt> parse(String imagePath) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Receipt scanning is only available on Android and iOS.',
      );
    }

    final InputImage image = InputImage.fromFilePath(imagePath);
    final TextRecognizer recognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    final BarcodeScanner barcodeScanner = BarcodeScanner(
      formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.aztec,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
      ],
    );

    try {
      final List<Object> results = await Future.wait<Object>([
        recognizer.processImage(image),
        barcodeScanner.processImage(image),
      ]);

      final RecognizedText recognised = results[0] as RecognizedText;
      final List<Barcode> barcodes = results[1] as List<Barcode>;

      final List<String> qrPayloads = barcodes
          .map((Barcode b) => b.rawValue ?? b.displayValue ?? '')
          .where((String v) => v.trim().isNotEmpty)
          .toList();

      return buildParsedReceipt(recognised.text, qrPayloads: qrPayloads);
    } finally {
      await recognizer.close();
      await barcodeScanner.close();
    }
  }
}

ReceiptOcrService create() => const MlKitReceiptOcrService();
