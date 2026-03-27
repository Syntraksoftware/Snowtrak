import 'package:syntrak/core/config/app_environment.dart';
import 'package:syntrak/main.dart' as app;

Future<void> main() async {
  await app.bootstrapAndRun(environment: AppEnvironment.dev);
}
