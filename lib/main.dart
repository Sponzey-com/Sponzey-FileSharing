import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/bootstrap.dart';

Future<void> main() async {
  await bootstrap(config: AppConfig.production());
}
