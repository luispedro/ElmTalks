# Quick Start

This is a quick start guide to create your own presentation using ElmTalks.

Alternatively, you can run the `quick-start.sh` script in an empty directory to automate all the steps below:

```bash
mkdir my-presentation && cd my-presentation
curl -sL https://raw.githubusercontent.com/luispedro/ElmTalks/main/quick-start.sh | bash
```

Step 0: Install [Elm](https://elm-lang.org/). This you need to do on your own.

Step 1: Create a new Elm project and install dependencies (which will be used by ElmTalks):

```bash
elm init
elm install elm/url
elm install elm/json
elm install elm-explorations/markdown
```

Step 2: Add ElmTalks as a git submodule & copy the `assets` folder to your project root:

```bash
git submodule add https://github.com/luispedro/ElmTalks.git
cp -r ElmTalks/assets .
```

Step 3: Edit your `elm.json` to include ElmTalks as a source directory:
```json
{
    "type": "application",
    "source-directories": [
        "src",
        "ElmTalks/src"
    ],
...
```

Step 4: Create a `src/Main.elm` file with the following content:

```elm
module Main exposing (main)

import Html exposing (Html)
import Slides exposing (mkSlide, cookSlides, Slide)
import SlideShow exposing (mkSlideShow, ProgramType)

slides : List (Slide msg)
slides =
    cookSlides
        [ mkSlide "Slide 1 Title" [ Html.text "Content for slide 1." ]
        , mkSlide "Slide 2 Title" [ Html.text "Content for slide 2." ]
        ]

main : ProgramType
main = mkSlideShow
            { title = "My Presentation"
            , slides = slides
            , mkFooter = \cur total -> Html.div [] [ Html.text (String.fromInt cur ++ " / " ++ String.fromInt total) ]
            }
```


Step 5: use the `elm reactor` or any other method to test your presentation.

```
elm reactor &
```

and go to [http://localhost:8000/src/Main.elm](http://localhost:8000/src/Main.elm)

Step 6: Build your project for production:

```bash
elm make src/Main.elm --optimize
```


Step 6 (alternative): Build your project for production using `ElmTalks/build.sh` and `copy-Media-files.py`:

```bash
cp -pir ElmTalks/build.sh .
cp -pir ElmTalks/copy-Media-files.py .
./build.sh
```

This will create a `dist` folder with an optimized `index.html` and `main.js` file, along with the necessary media files which are copied from `Media/`.

