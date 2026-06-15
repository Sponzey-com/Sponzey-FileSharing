import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';

void main() {
  test('macOS default receive path stays under user Downloads', () {
    final path = AppPlatformDirectories.defaultReceivePathFor(
      platform: AppDesktopPlatform.macos,
      environment: const {'HOME': '/Users/alice'},
      currentDirectory: '/tmp/app',
    );

    expect(path, '/Users/alice/Downloads/Sponzey FileSharing');
  });

  test('Windows default receive path stays under user Downloads', () {
    final path = AppPlatformDirectories.defaultReceivePathFor(
      platform: AppDesktopPlatform.windows,
      environment: const {'USERPROFILE': r'C:\Users\atom'},
      currentDirectory: r'C:\src\SponzeyFileSharing',
    );

    expect(path, r'C:\Users\atom\Downloads\Sponzey FileSharing');
  });

  test(
    'Linux default receive path uses XDG download directory when present',
    () {
      final path = AppPlatformDirectories.defaultReceivePathFor(
        platform: AppDesktopPlatform.linux,
        environment: const {
          'HOME': '/home/atom',
          'XDG_DOWNLOAD_DIR': r'$HOME/Files/Downloads',
        },
        currentDirectory: '/tmp/app',
      );

      expect(path, '/home/atom/Files/Downloads/Sponzey FileSharing');
    },
  );

  test('Linux default receive path falls back to home Downloads', () {
    final path = AppPlatformDirectories.defaultReceivePathFor(
      platform: AppDesktopPlatform.linux,
      environment: const {'HOME': '/home/atom'},
      currentDirectory: '/tmp/app',
    );

    expect(path, '/home/atom/Downloads/Sponzey FileSharing');
  });

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
