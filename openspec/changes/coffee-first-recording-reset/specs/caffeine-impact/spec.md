# Caffeine Impact Spec

## Requirements
- The app must compute current estimated caffeine remaining from timestamped intake records and user settings.
- The app must render a caffeine-over-time curve and mark the configured sleep time on that curve.
- The app must expose the projected caffeine remaining at the configured sleep time.
- The metabolism model must stay deterministic and reusable across iPhone, Widget, Watch, and future platforms.
