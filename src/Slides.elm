module Slides exposing (Slide, SlideType(..), SlideShow, mkSlide, mkIncrementalSlide, mdToHtml, tagSlideGroup, mkSlideGroup)

import Html exposing (..)
import Html.Attributes as HtmlAttr
import Html.Events exposing (..)

import Chart as C
import Svg as S
import Chart.Attributes as CA

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Json.Decode exposing (Decoder)

import Markdown

type SlideType = FirstSlideInGroup | Follower | Special

type alias Slide msg =
    { content : Html msg
    , slideType : SlideType
    }
type alias SlideShow msg = List (Slide msg)


mkSlide : String -> List (Html msg) -> Slide msg
mkSlide title body =
    { content = Html.div
        [HtmlAttr.class "slide"]
        (Html.h2 [] [Html.text title] :: body)
    , slideType = FirstSlideInGroup
    }


tagSlideGroup : List (Slide msg) -> List (Slide msg)
tagSlideGroup sl = case sl of
    [] -> []
    (h :: rest) -> h :: List.map (\s -> { s | slideType = Follower }) rest

mkSlideGroup : String -> List (List (Html msg)) -> List (Slide msg)
mkSlideGroup title parts =
    List.map (mkSlide title) parts
        |> tagSlideGroup

mkIncrementalSlide : String -> List (List (Html msg)) -> List (Slide msg)
mkIncrementalSlide title parts =
    List.range 1 (List.length parts)
    |> List.map (\ix ->
            mkSlide title (List.concat (List.take ix parts)))
    |> tagSlideGroup

markdownOptions =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }
mdToHtml = Markdown.toHtmlWith markdownOptions []




