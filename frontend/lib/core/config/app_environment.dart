enum AppEnvironment { dev, staging, prod }
// staging = pre-production environment for final testing, prod = live environment for end users, dev = development environment for active development and testing, with more logging and debugging features enabled.

extension AppEnvironmentX on AppEnvironment {
  static AppEnvironment fromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'staging':
        return AppEnvironment.staging;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  String get value {
    switch (this) {
      case AppEnvironment.dev:
        return 'dev';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.prod:
        return 'prod';
    }
  }
}
