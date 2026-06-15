import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';

void main() {
  test('detects legacy macOS sandbox receive directory', () {
    expect(
      AppPlatformDirectories.looksLikeLegacySandboxReceivePath(
        '/Users/alice/Library/Containers/com.sponzey.filesharing/Data/Downloads/Sponzey FileSharing',
      ),
      isTrue,
    );
    expect(
      AppPlatformDirectories.looksLikeLegacySandboxReceivePath(
        '/Users/alice/Downloads/Sponzey FileSharing',
      ),
      isFalse,
    );
  });
}
