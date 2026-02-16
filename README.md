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

## Footer Arguments

The `mkFooter` field of `mkSlideShow` takes a function that receives two
arguments: the current slide number and the total number of slides.  This
function returns the `Html` that should appear at the bottom of every slide,
allowing you to customise the footer layout or omit it entirely.

## HtmlSimple Utilities

Elm Talks ships with a small utility module named `HtmlSimple`.  It contains
convenience functions for building slide content, such as helpers for floating
elements, sized images, simple lists, and converting Markdown to HTML.  Import
`HtmlSimple` when you want to lean on these utilities instead of writing the
markup by hand.

