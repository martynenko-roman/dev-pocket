# Design system

## Theme.swift
System accent only. Native semantic primary/secondary text and window surfaces.
No accent picker: the source spec asks for the Mac's own accent.

## Grid.swift
Space: 4, 8, 12, 16, 20, 24, 32. Page/panel margin 20; related controls 8; sections 20.
Native Forms own their row layout. Probe custom panel groups.

## Tokens.swift
Layout owns panel width (400), Settings width (560), round button size (52), symbol size (20), and toast dimensions.
Radius owns toast rounding. Motion owns the 1.5-second toast lifetime.
Use system button, toggle, menu, and picker styles. On/off has an accessibility value and visible state; color alone is insufficient.
No custom animation. Respect Reduce Transparency through a semantic opaque toast background.
