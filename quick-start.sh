#!/usr/bin/env bash
set -euo pipefail

# Quick Start script for ElmTalks
# Creates a new presentation project in the current (empty) directory.

# --- Pre-flight checks ---

# 1. Current directory must be completely empty
if [ "$(ls -A .)" ]; then
    echo "Error: Current directory is not empty." >&2
    echo "Please run this script from an empty directory." >&2
    exit 1
fi

# 2. Required tools
for cmd in elm git python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: '$cmd' is not installed or not in PATH." >&2
        exit 1
    fi
done

# --- Step 1: Initialise Elm project and install dependencies ---
echo "==> Initialising Elm project..."
echo y | elm init

echo "==> Installing Elm dependencies..."
echo y | elm install elm/url
echo y | elm install elm/json
echo y | elm install elm-explorations/markdown

# --- Step 2: Add ElmTalks as a git submodule & copy assets ---
echo "==> Initialising git repository..."
git init

echo "==> Adding ElmTalks as a git submodule..."
git submodule add https://github.com/luispedro/ElmTalks.git

echo "==> Copying assets..."
cp -r ElmTalks/assets .

# --- Step 3: Patch elm.json to include ElmTalks/src ---
echo "==> Patching elm.json to include ElmTalks/src..."
python3 -c "
import json, sys
with open('elm.json', 'r') as f:
    data = json.load(f)
dirs = data.get('source-directories', [])
if 'ElmTalks/src' not in dirs:
    dirs.append('ElmTalks/src')
    data['source-directories'] = dirs
with open('elm.json', 'w') as f:
    json.dump(data, f, indent=4)
    f.write('\n')
"

# --- Step 4: Create starter Main.elm ---
echo "==> Creating src/Main.elm..."
mkdir -p src
cat > src/Main.elm << 'ELMEOF'
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
ELMEOF

# --- Step 5: Copy build helpers ---
echo "==> Copying build scripts..."
cp -p ElmTalks/build.sh .
cp -p ElmTalks/copy-Media-files.py .

# --- Step 6: Set up git ---
echo "==> Creating .gitignore..."
cat > .gitignore << 'EOF'
elm-stuff/
dist.backup/
dist/
index.html
EOF

echo "==> Adding files to git..."
git add .gitignore elm.json src/Main.elm assets build.sh copy-Media-files.py

# --- Done ---
echo ""
echo "Project created successfully!"
echo ""
echo "To preview:  elm reactor   then open http://localhost:8000/src/Main.elm"
echo "To build:    ./build.sh"
echo ""
echo "You may want to commit the initial project:"
echo ""
echo "  git commit -m 'Initial ElmTalks presentation'"
