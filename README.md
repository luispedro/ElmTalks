# Elm Talks

Elm Talks is a lightweight framework for building slide presentations in [Elm](https://elm-lang.org/).
Slides are described using Elm code and rendered to HTML so that they can be viewed in any browser.

## Building

The repository includes a helper script for compiling the presentation and copying the media files:

```bash
./build.sh
```

The build output is placed in the `dist/` directory.

## Usage

Slides are created using helper functions from `Slides` and shown with `SlideShow.mkSlideShow`.
Below is a small example that builds two slides and runs the slide show:

```elm
import Html exposing (text)
import Slides exposing (RawSlide, mkSlide, mkSteppedSlide)
import SlideShow

slides : List (RawSlide Never)
slides =
    [ mkSlide "Welcome" [ text "Hello, world!" ]
    , mkSteppedSlide "Steps"
        [ [ text "First" ]
        , [ text "Second" ]
        , [ text "Third" ]
        ]
    ]

main : Program () () msg
main =
    SlideShow.mkSlideShow { title = "Demo", slides = Slides.cookSlides slides, mkFooter = \_ _ -> Html.text "" }
```

Compile `main` with `elm make` and open the resulting HTML file to view the presentation.
