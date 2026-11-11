# Fix log

## Countdown briefly exceeds the selected duration

Symptom: after selecting 15 minutes in the native UI, status briefly read
15:01 while the button read 15:00.

Cause: periodic timeline dates could precede the new session's start, and
the panel used separate timelines for its button and status.

Fix: clamp the remaining interval to the session's original length, and
use one timeline date for both panel labels. A real-session self-test
covers a stale timeline date.

Rule: format one shared timeline date and cap it at the configured session length.
