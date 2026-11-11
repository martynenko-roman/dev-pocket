# Build verification

Checked on 2026-11-11. No successful compile, launch, or visual verification.

## Observations

- macOS: 26.6.2.
- `swift --version`: Apple Swift 6.3.3.
- `xcode-select -p`: `/Library/Developer/CommandLineTools`.
- No full Xcode installation was found in `/Applications`.
- `actool` is unavailable in the selected developer tools. BAMA's app icon
  compilation and Icon Composer review require full Xcode.

## Swift package failure

The unmodified template manifest fails before app compilation:

```text
reference to member 'v26' cannot be resolved without a contextual type
type 'Array<SwiftSetting>.ArrayLiteralElement' has no member 'defaultIsolation'
```

The selected `ManifestAPI/PackageDescription.swiftmodule` contains public
interfaces with `v26` and `defaultIsolation`, but private interfaces dated
February 2024 that lack them. This is evidence of inconsistent toolchain
files, rather than an app implementation failure.

A temporary diagnostic using the string platform version and compiler
isolation flags passed those checks but failed to link a
`PackageDescription.Package` initializer. The manifest was restored to the
BAMA template after this diagnostic.

Build attempts used scratch, module, and package caches under `/private/tmp`
to avoid writes to restricted user Library directories. No system developer
tool files were changed.

## Resume

Select a consistent full Xcode toolchain with Swift 6.2 or later, then rerun
the template build, tests, icon compilation, and light/dark snapshots.
Implement the menu bar architecture from `SPEC.md` after the baseline passes.
All feature stories remain `todo` until their acceptance checks pass.
