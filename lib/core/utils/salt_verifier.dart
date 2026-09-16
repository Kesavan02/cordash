import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';

/// Utility to compute and verify the anti-plagiarism SALT deterministically.
class SaltVerifier {
  /// Computes SHA256("${packageName}:${firstGitCommitHash}") in hex lowercase.
  static String computeSalt(String packageName, String firstGitCommitHash) {
    final rawInput = '$packageName:$firstGitCommitHash';
    final bytes = utf8.encode(rawInput);
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase();
  }

  /// Verifies that the computed salt matches the static embedded AppConstants.antiPlagiarismSalt.
  static bool verifyEmbeddedSalt() {
    final computed = computeSalt(
      AppConstants.packageName,
      AppConstants.firstGitCommitHash,
    );
    return computed == AppConstants.antiPlagiarismSalt;
  }
}
