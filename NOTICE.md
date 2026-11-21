# Notice

Furoshiki is a modified version of **Vorssaint** (https://github.com/vorssaint/vorssaint-utils),
copyright (C) 2026 Vorssaint, licensed under the GNU General Public License,
version 3 or (at your option) any later version. See [LICENSE](LICENSE).

This fork is based on upstream commit `faada18df1b90572cddc6182ce7fc04e0eb1435c`.

## Modifications made in this fork (2026-11-21)

- Renamed the app, executable, source folder and all user-facing text from
  "Vorssaint" to "Furoshiki", including every localization.
- New bundle identifier `io.github.colinnoah.furoshiki` (Developer variant:
  `io.github.colinnoah.furoshiki.dev`), with matching helper and pasteboard identifiers.
- New app icon, menu bar glyph and logo (a knotted furoshiki cloth bundle with a
  seigaiha wave pattern); sources in [docs/brand](docs/brand). The upstream icon,
  logo, brand assets, README screenshots and release showcase video were removed.
- Update checks, release downloads and the AI price list point at this
  repository (`colinnoah/Furoshiki`) instead of upstream.
- The upstream share and feedback server (`screenshots.vorssaint.com`) was
  replaced by the placeholder `share.furoshiki.invalid`, so temporary links and
  in-app feedback stay inactive until this project runs its own backend.
- Donation, website, Discord and social links point at this repository.
- README, NOTICE and TRADEMARKS rewritten for the fork; other docs renamed.

The `Copyright (C) 2026 Vorssaint` notices in the original source files are kept
unchanged. Furoshiki is not affiliated with or endorsed by the Vorssaint project.

Third-party code bundled by upstream keeps its own license, for example
[cgif](Sources/RecorderGIFCodec/vendor/cgif/LICENSE) (MIT).
