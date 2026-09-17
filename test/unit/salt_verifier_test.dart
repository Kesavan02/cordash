import 'package:flutter_test/flutter_test.dart';
import 'package:cordash/core/constants/app_constants.dart';
import 'package:cordash/core/utils/salt_verifier.dart';

void main() {
  group('Anti-Plagiarism SALT Verification', () {
    test('SALT calculation matches deterministic SHA256 formula', () {
      final computed = SaltVerifier.computeSalt(
        'com.example.cordash',
        '4b8fea420da7b41d0a7c59535ddfaacfb0bc6e6e',
      );

      expect(
        computed,
        equals(
          '53e4cf58eb6634c6149e062b2110da8712b6f9d1403a1d7b735589004348d5c7',
        ),
      );
    });

    test('SaltVerifier asserts embedded AppConstants.antiPlagiarismSalt', () {
      expect(SaltVerifier.verifyEmbeddedSalt(), isTrue);
      expect(
        AppConstants.antiPlagiarismSalt,
        equals(
          '53e4cf58eb6634c6149e062b2110da8712b6f9d1403a1d7b735589004348d5c7',
        ),
      );
    });
  });
}
