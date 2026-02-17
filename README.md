# Elm Talks

Elm Talks is a lightweight presentation framework written in [Elm](https://elm-lang.org/). Slides are defined in Elm code and compiled into static HTML, making it easy to host the result anywhere.

## Building

Run `./build.sh` to compile the sources and produce a `dist` directory containing `index.html` and assets. The build script invokes `elm make` and copies media files.

To start a new project, see the [Quick Start Guide](QUICK-START.md) or run the following in an empty directory to set everything up automatically:

```bash
mkdir my-presentation && cd my-presentation
curl -sL https://raw.githubusercontent.com/luispedro/ElmTalks/main/quick-start.sh | bash
```

## Example

Below is a minimal program that constructs a short slideshow.

```elm
module Main exposing (main)

import Html exposing (Html, div, text)
import SlideShow exposing (mkSlideShow)
import Slides exposing (SlideList, mkSlide, cookSlides)
import String

slides : SlideList msg
slides =
    cookSlides
        [ mkSlide "Intro" [ text "Welcome to Elm Talks" ]
        , mkSlide "Finish" [ text "Thanks!" ]
        ]

footer : Int -> Int -> Html msg
footer current total =
    div [] [ text (String.fromInt current ++ "/" ++ String.fromInt total) ]

main =
    mkSlideShow
        { title = "Demo"
        , slides = slides
        , mkFooter = footer
        }
```

Running the example and opening the generated `index.html` will display a two slide presentation.

## Slides, RawSlides, and Cooking

Slide content is defined using the `Slides` module.  A `RawSlide` represents the
unprocessed form of a slide.  It can be a single slide, a group of slides (for
incremental or stepped content), or a collection of extra slides that are moved
to the end.  The `cookSlides` function converts a list of `RawSlide` values into
the plain `Slide` list consumed by `mkSlideShow`.

The following functions create `RawSlide` values:

- `mkSlide title body` — a single slide with the given title and body elements.
- `mkSteppedSlide title parts` — a group of slides sharing the same title where each step shows only the elements for that step (the `parts` list). Use this when each step replaces the previous content.
- `mkIncrementalSlide title parts` — like `mkSteppedSlide` but each step accumulates all previous parts so content builds up progressively.
- `skipSlide rawSlide` — drops a slide entirely; useful for temporarily hiding a slide without deleting it.
- `mkExtra rawSlide` — marks a slide (or group) as extra so that `cookSlides` moves it to the end of the presentation regardless of where it appears in the source list.

## Slide Types

The `SlideType` tells the framework how to render a slide:

- `FirstSlideInGroup` — the default; the slide is rendered with the standard header, footer, and click-to-advance behaviour.
- `Follower` — used internally for the non-first steps of a stepped/incremental group.
- `Special` — renders the slide without the surrounding header or footer wrapper.  Useful for title slides or full-bleed layouts.
- `Extra` — slides moved to the end by `mkExtra` / `cookSlides`.

You rarely need to set `slideType` directly; `mkSlide` and friends set it for you.

## Footer Arguments

The `mkFooter` field of `mkSlideShow` takes a function that receives two
arguments: the current slide number and the total number of slides.  This
function returns the `Html` that should appear at the bottom of every slide,
allowing you to customise the footer layout or omit it entirely.

## HtmlSimple Utilities

Elm Talks ships with a small utility module named `HtmlSimple`.  Import it when
you want to lean on these helpers instead of writing the markup by hand.

| Function | Description |
|---|---|
| `floatLeftDiv width content` | Wraps `content` in a left-floating `div` of the given CSS width |
| `floatRightDiv width content` | Same, but floats right |
| `floatClear` | Clears floats (equivalent to `<div style="clear:both">`) |
| `textUL items` | Unordered list from a list of strings |
| `textOL items` | Ordered list from a list of strings |
| `img50 src` | Image at 50% width |
| `img80 src` | Image at 80% width |
| `imgw width src` | Image at an arbitrary CSS width |
| `p text` | Paragraph from a plain string |
| `h1 text` | `<h1>` from a plain string |
| `h2 text` | `<h2>` from a plain string |
| `h3 text` | `<h3>` from a plain string |
| `textA url label` | Hyperlink |
| `underline` | `Html.Attribute` that underlines an element |
| `padTop1` | `Html.Attribute` that adds `1em` of top padding |
| `mdToHtml markdown` | Renders a Markdown string to `Html` (GitHub-flavoured, tables enabled) |

Paths that begin with `Media/` are automatically prefixed with `/` so that they
work correctly when served from the project root.

## SlideBlocks

The `SlideBlocks` module provides a higher-level way to build stepped slides
using named fragments rather than manually constructing lists of steps.

```elm
import SlideBlocks exposing (mkBlockedSlide, allFragments, nextFragmentStay, nextFragment, someFragments)

mySlide : Slides.RawSlide msg
mySlide =
    mkBlockedSlide "Demo"
        [ allFragments    [ Html.p [] [ Html.text "Always visible" ] ]
        , nextFragmentStay [ Html.p [] [ Html.text "Appears on step 1, stays" ] ]
        , nextFragment     [ Html.p [] [ Html.text "Appears on step 2, gone on step 3" ] ]
        , nextFragmentStay [ Html.p [] [ Html.text "Appears on step 3, stays" ] ]
        ]
```

Fragment helpers:

- `allFragments body` — the block is visible on every step.
- `nextFragmentStay body` — the block appears on the next step and remains visible for all subsequent steps.
- `nextFragment body` — the block appears on the next step only (hidden again afterwards).
- `someFragments indices body` — the block is visible only on the explicitly listed step indices (zero-based).

## Keyboard Shortcuts

| Key(s) | Action |
|---|---|
| `Space`, `N`, `J`, `ArrowRight`, `PageDown` | Next slide |
| `P`, `K`, `ArrowLeft`, `PageUp` | Previous slide |
| `F`, `H` | First slide |
| `L` | Last slide |
| `O` | Toggle overview mode |
| `A` | Toggle print / all-slides mode |
| `?` | Toggle help overlay |
| `0`–`9` | Jump to slide 1, 5, 10, … 45 respectively |

## URL Fragment Navigation

The presentation state is reflected in the URL fragment as `#slideNumber.offset`,
where `slideNumber` is the one-based slide group index and `offset` is the step
within that group.  Sharing or bookmarking a URL preserves the exact position.

