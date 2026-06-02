# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

ElmTalks is a small **presentation framework library** written in Elm 0.19.1. The four modules under `src/` (`Slides`, `SlideShow`, `SlideBlocks`, `HtmlSimple`) are intended to be consumed by downstream presentation projects that supply their own `src/Main.elm`. There is no `Main.elm` in this repo — `build.sh` is shipped for downstream users, not for building anything here.

Consequently:
- The canonical way to "use" the library is documented in `QUICK-START.md` (add this repo as a git submodule, add `ElmTalks/src` to `source-directories` in the downstream `elm.json`, write a `Main.elm` that calls `SlideShow.mkSlideShow`).
- `quick-start.sh` is the bootstrap script users curl-pipe; treat it as user-facing tooling, not a dev script.
- Running `./build.sh` inside *this* repo will fail (no `src/Main.elm`). To smoke-test library changes, build inside a downstream presentation that points at this checkout.

## Architecture

The library has three layers, smallest first:

1. **`Slides`** — defines the data model. A `Slide msg` is `{ content : Html msg, slideType : SlideType }`. Authors don't build `Slide` directly; they build `RawSlide msg` values (`RawSlide` for one slide, `RawSlideGroup` for stepped/incremental groups, `RawExtraSlides` for slides moved to the end). `cookSlides : List (RawSlide msg) -> List (Slide msg)` "cooks" them: it moves `RawExtraSlides` to the end and flattens groups. `SlideType` (`FirstSlideInGroup` / `Follower` / `Special` / `Extra`) controls rendering in `SlideShow`; `Follower` is set automatically for non-first members of a stepped group via `tagSlideGroup`.

2. **`SlideBlocks`** — a higher-level authoring layer on top of `Slides.mkSteppedSlide`. `mkBlockedSlide title blocks` takes blocks tagged with a `SlidePresence` (`All` / `NextSingle` / `NextStay` / `In [indices]`) and expands them into the per-step body lists that `mkSteppedSlide` expects. Note the quirk in `mkBlockedSlide`: if the first block is `All` it is silently promoted to `NextStay` so the step count is well-defined.

3. **`SlideShow`** — the Elm `Browser.application` (declared as a `port module`) that renders cooked slides. It owns the entire runtime: `Model` (`position`, `Nav.Key`, `Mode`, `WindowRole`, timer state), keyboard handling (`handleKeys`), URL fragment parsing/writing, and the display modes (`SingleSlide` / `Overview` / `Print` / `Help`) plus a separate `Speaker` view selected by `WindowRole`. Authors get at it only through `mkSlideShow : SlideContent -> ProgramType`.

**Two coordinate systems** run through `SlideShow` and are easy to confuse — the file says so explicitly at line 17:
- *position* — zero-based index into the cooked `List (Slide msg)`. Used internally.
- *slide number* — one-based count of slide **groups** (a stepped group counts as one). Used in the URL fragment and in the footer callback `mkFooter : Int -> Int -> Html msg`.
Anything that crosses the boundary (URL parsing in `init`, `GotoSlideNumber`, the footer) must convert between the two.

**URL fragment grammar.** The fragment encodes both the window role and the location:
- `#N` or `#N.O` → audience view, slide N (optional offset O).
- `#s/N` or `#s/N.O` → speaker view, slide N (optional offset O).
`parseFragment` decodes both forms in `init`; `fragmentFor` round-trips them in `setPosition`. The `s/` prefix is the only marker of speaker role — `Model.role` is set once at init and never changes during a session.

**Speaker/audience sync via ports.** `SlideShow` declares three ports — `broadcastPosition : Int -> Cmd msg`, `receivePosition : (Int -> msg) -> Sub msg`, `openSpeakerWindow : () -> Cmd msg` — wired in `index.html` to a `BroadcastChannel('elmtalks')` and `window.open`. Echo prevention has two layers: `RemoteGotoPosition` applies remote updates with `broadcast=False` in `setPosition`, and the broadcast cmd is `Cmd.none` whenever `real_p == model.position`. Any downstream `index.html` that does not wire these ports silently degrades to single-window operation (the subscribe calls just never fire).

**`HtmlSimple`** is an independent helper module of thin wrappers around `Html` builders (lists, floats, sized images, markdown via `elm-explorations/markdown`). One non-obvious behaviour: image helpers auto-prefix any `src` starting with `Media/` with a leading `/`, so the same source works both under `elm reactor` and when served from the project root.

## Build output

The library now ships a hand-written `index.html` at the repo root. Downstream projects copy this file alongside `build.sh` and `copy-Media-files.py`. `build.sh` runs `elm make src/Main.elm --optimize --output=main.js` (not the default index.html output) so that the JS-port shim in `index.html` stays intact across rebuilds. Anything that depends on the Elm-generated index.html (notably `copy-Media-files.py`, which scans for `Media/...` paths) reads `main.js` instead.

## Media pipeline

`copy-Media-files.py` post-processes the compiled `main.js` for downstream projects. It scans the bundled JS for `Media/...` paths and copies the matching files from `Media/` into `dist/Media/`. It also recognises two patterns that need globbing:
- `pat_stepped` — paths like `Media/foo_stepped-` (i.e. files that are intentionally generated as a numbered series).
- `pat_fromString` — Elm's optimised output for string concatenation around `String.fromInt`, which serialises as `' + ($elm$core$String$fromInt(...) + '`. The script substitutes `*` for that fragment so the resulting glob picks up all numeric variants.
If you add a new way to construct image paths in Elm, check whether the optimised JS emits a form this script will still recognise.

## Working in the library

- Elm version is pinned to 0.19.1 (`elm.json`). Dependencies of note: `elm-explorations/markdown` (used by `HtmlSimple.mdToHtml`), `pablohirafuji/elm-syntax-highlight`, `rundis/elm-bootstrap`, `Garados007/elm-svg-parser`.
- There are no tests configured (`test-dependencies` is empty).
- A Nix flake exists (`flake.nix` → `default.nix`); `netlify-cli.nix` provides a separate shell for deploys. They are for users building/hosting presentations, not for library development.
- `.gitignore` excludes `dist/`, `dist.backup`, `result`, `node_modules`, `package*.json`, and `elm-stuff` — none of those should ever be committed. The hand-written `index.html` at the repo root *is* tracked (it is the JS shim template downstream projects copy).
