module Slides exposing
    ( RawSlide(..)
    , Slide
    , SlideType(..)
    , SlideList

    , mkSlide
    , mkIncrementalSlide
    , mkSteppedSlide

    , cookSlides
    , skipSlide
    , mkExtra
    )


import Html exposing (..)
import Html.Attributes as HtmlAttr
import Html.Events exposing (..)

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Json.Decode exposing (Decoder)

type SlideType = FirstSlideInGroup | Follower | Special | Extra

type alias Slide msg =
    { content : Html msg
    , slideType : SlideType
    }
type alias SlideList msg = List (Slide msg)

type RawSlide msg = RawSlide (Slide msg) | RawSlideGroup (List (Slide msg)) | RawExtraSlides (List (Slide msg))

mkSlide : String -> List (Html msg) -> RawSlide msg
mkSlide title body = RawSlide <|
    { content = Html.div
        [HtmlAttr.class "slide"]
        (Html.h2 [] [Html.text title] :: body)
    , slideType = FirstSlideInGroup
    }


mkSlideSimple : String -> List (Html msg) -> Slide msg
mkSlideSimple title body =
    { content = Html.div
        [HtmlAttr.class "slide"]
        (Html.h2 [] [Html.text title] :: body)
    , slideType = FirstSlideInGroup
    }


tagSlideGroup : List (Slide msg) -> List (Slide msg)
tagSlideGroup sl = case sl of
    [] -> []
    (h :: rest) -> h :: List.map (\s -> { s | slideType = Follower }) rest

mkSteppedSlide : String -> List (List (Html msg)) -> RawSlide msg
mkSteppedSlide title parts =
    List.map (mkSlideSimple title) parts
        |> tagSlideGroup
        |> RawSlideGroup

mkIncrementalSlide : String -> List (List (Html msg)) -> RawSlide msg
mkIncrementalSlide title parts =
    List.range 1 (List.length parts)
    |> List.map (\ix ->
            mkSlideSimple title (List.concat (List.take ix parts)))
    |> tagSlideGroup
    |> RawSlideGroup

cookSlides : List (RawSlide msg) -> List (Slide msg)
cookSlides slides =
    moveExtrasToEnd slides
    |> List.concatMap cookSlide

cookSlide : RawSlide msg -> List (Slide msg)
cookSlide s = case s of
    RawSlide sl -> [sl]
    RawSlideGroup sls -> sls
    RawExtraSlides sls -> sls


skipSlide : RawSlide msg -> RawSlide msg
skipSlide _ = RawSlideGroup []

tagExtra : Slide msg -> Slide msg
tagExtra s = { s | slideType = Extra }
mkExtra : RawSlide msg -> RawSlide msg
mkExtra s =
    let
        sl = case s of
            RawSlide ss -> [ss]
            RawSlideGroup sg -> sg
            RawExtraSlides sg -> sg
    in RawExtraSlides (List.map tagExtra sl)

moveExtrasToEnd : List (RawSlide msg) -> List (RawSlide msg)
moveExtrasToEnd slides =
    let
        isNormal s = case s of
                        RawExtraSlides _ -> False
                        _ -> True
    in List.filter isNormal slides ++ List.filter (not << isNormal) slides

