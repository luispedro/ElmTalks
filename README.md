# Elm Talks

Elm Talks is a lightweight presentation framework written in [Elm](https://elm-lang.org/). Slides are defined in Elm code and compiled into static HTML, making it easy to host the result anywhere.

## Building

Run `./build.sh` to compile the sources and produce a `dist` directory containing `index.html` and assets. The build script invokes `elm make` and copies media files.

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
