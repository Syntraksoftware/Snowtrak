import 'package:snowtrak/core/config/app_environment.dart';
import 'package:snowtrak/main.dart' as app;

Future<void> main() async {
  await app.bootstrapAndRun(environment: AppEnvironment.staging);
}
