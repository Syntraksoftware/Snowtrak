fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios dev

```sh
[bundle exec] fastlane ios dev
```

Validate and build a development iOS artifact locally

### ios staging

```sh
[bundle exec] fastlane ios staging
```

Build and upload to TestFlight for staging

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Backwards-compatible alias for the staging lane

### ios production

```sh
[bundle exec] fastlane ios production
```

Build and upload the production release to App Store Connect

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
