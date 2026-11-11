# DevPocket

A native macOS menu bar utility, based on the BAMA Toolbox specification.

## Project status

The BAMA brief and backlog have been imported and the SwiftUI template has
been scaffolded. App features are not implemented yet. The current source
still contains the template's sample item interface.

- [Brief](docs/BRIEF.md): source brief, with the requested DevPocket name.
- [Stories](docs/STORIES.md): all 11 source stories, with the requested name.
- [Source specification](docs/SPEC.md): complete, unchanged upstream spec.
- [Build status](docs/BUILD-STATUS.md): current verification blockers.

Bundle identifier: `com.romanmartynenko.devpocket`.

## BAMA workflow

Completed: spec import and scaffold creation.

Next: resolve the developer toolchain, verify the template build, then use
`mac-design`, `design-system`, and `app-icon` before implementing the M1
stories through `improve-loop`.

## Build

Requires macOS 26+, a consistent Swift 6.2+ toolchain, and full Xcode for
Icon Composer and asset compilation. With those installed:

```sh
./build.sh --open
```

Source: https://github.com/daveebbelaar/bama/blob/main/specs/toolbox.md
