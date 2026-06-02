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

3. **`SlideShow`** — the Elm `Browser.application` that renders cooked slides. It owns the entire runtime: `Model` (current `position`, `Nav.Key`, `Mode`), keyboard handling (`handleKeys`), URL fragment parsing/writing in the form `#slideNumber.offset`, and the four display modes (`SingleSlide` / `Overview` / `Print` / `Help`). Authors get at it only through `mkSlideShow : SlideContent -> ProgramType`.

**Two coordinate systems** run through `SlideShow` and are easy to confuse — the file says so explicitly at line 17:
- *position* — zero-based index into the cooked `List (Slide msg)`. Used internally.
- *slide number* — one-based count of slide **groups** (a stepped group counts as one). Used in the URL fragment and in the footer callback `mkFooter : Int -> Int -> Html msg`.
Anything that crosses the boundary (URL parsing in `init`, `GotoSlideNumber`, the footer) must convert between the two.

**`HtmlSimple`** is an independent helper module of thin wrappers around `Html` builders (lists, floats, sized images, markdown via `elm-explorations/markdown`). One non-obvious behaviour: image helpers auto-prefix any `src` starting with `Media/` with a leading `/`, so the same source works both under `elm reactor` and when served from the project root.

## Media pipeline

`copy-Media-files.py` post-processes the compiled `index.html` for downstream projects. It scans the bundled JS for `Media/...` paths and copies the matching files from `Media/` into `dist/Media/`. It also recognises two patterns that need globbing:
- `pat_stepped` — paths like `Media/foo_stepped-` (i.e. files that are intentionally generated as a numbered series).
- `pat_fromString` — Elm's optimised output for string concatenation around `String.fromInt`, which serialises as `' + ($elm$core$String$fromInt(...) + '`. The script substitutes `*` for that fragment so the resulting glob picks up all numeric variants.
If you add a new way to construct image paths in Elm, check whether the optimised JS emits a form this script will still recognise.

## Working in the library

- Elm version is pinned to 0.19.1 (`elm.json`). Dependencies of note: `elm-explorations/markdown` (used by `HtmlSimple.mdToHtml`), `pablohirafuji/elm-syntax-highlight`, `rundis/elm-bootstrap`, `Garados007/elm-svg-parser`.
- There are no tests configured (`test-dependencies` is empty).
- A Nix flake exists (`flake.nix` → `default.nix`); `netlify-cli.nix` provides a separate shell for deploys. They are for users building/hosting presentations, not for library development.
- `.gitignore` excludes `index.html`, `dist/`, `dist.backup`, `result`, `node_modules`, `package*.json`, and `elm-stuff` — none of those should ever be committed.
