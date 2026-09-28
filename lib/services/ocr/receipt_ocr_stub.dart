import 'receipt_ocr.dart';

class StubReceiptOcrService implements ReceiptOcrService {
  const StubReceiptOcrService();

  @override
  bool get isSupported => false;

  @override
  Future<ParsedReceipt> parse(String imagePath) async {
    throw UnsupportedError(
      'Receipt scanning is only available on Android and iOS. '
      'Please enter the expense manually.',
    );
  }
}

ReceiptOcrService create() => const StubReceiptOcrService();
