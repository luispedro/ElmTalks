module SlideShow exposing (mkSlideShow, ProgramType)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (onClick)

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Url
import Json.Decode exposing (Decoder)

import HtmlSimple as HS

import Slides exposing (Slide, SlideType(..), SlideList)

{- The term `position` will refer to the internal counter (zero-based, indexes
 - into the slides list) and the term `slide number` will be the human readable
 - version (one-based, counts by groups)
 -}

type Mode = SingleSlide | Overview | Print | Help
type alias Model =
    { position : Int
    , key : Nav.Key
    , mode : Mode
    }


type Msg
    = NoMsg
    | NavTo String
    | GotoSlideNumber Int Int
    | GotoPosition Int
    | PopToPosition Int
    | NextSlide
    | PreviousSlide
    | LastSlide
    | FirstSlide
    | ToggleOverviewMode
    | TogglePrintMode
    | ToggleHelpMode


type alias SlideContent =
    { title : String
    , slides : List (Slide Msg)
    , mkFooter : Int -> Int -> Html Msg
    }


type alias ProgramType = Program () Model Msg
mkSlideShow : SlideContent -> ProgramType
mkSlideShow content =
    Browser.application
        { init = init content
        , view = view content
        , update = update content
        , subscriptions = \_ -> Browser.Events.onKeyUp handleKeys
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }

init : SlideContent -> () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init content () u k =
    let
        (islide, off) = case u.fragment of
           Nothing -> (1, 0)
           Just f ->
               let
                    tokens = String.split "." f
               in case tokens of
                    [s] -> case String.toInt s
                        of Just i -> (i, 0)
                           Nothing -> (1, 0)
                    [s, o] -> case (String.toInt s, String.toInt o) of
                        (Just i, Just on) -> (i, on)
                        _ -> (1, 0)
                    _ -> (1, 0)
    in update content (GotoSlideNumber islide off) { position = 0, key = k, mode = SingleSlide }

handleKeys : Decoder Msg
handleKeys =
    Json.Decode.string
        |> Json.Decode.field "key"
        |> Json.Decode.andThen (\k ->
                if List.member k [" ", "n", "N", "j", "J", "ArrowRight", "PageDown"]
                then Json.Decode.succeed NextSlide
                else if List.member k ["p", "P", "k", "K", "ArrowLeft", "PageUp"]
                then Json.Decode.succeed PreviousSlide
                else if List.member k ["f", "F", "h", "H"]
                then Json.Decode.succeed FirstSlide
                else if List.member k ["l", "L"]
                then Json.Decode.succeed LastSlide
                else if k == "0"
                then Json.Decode.succeed (GotoSlideNumber 1 0)
                else if k == "1"
                then Json.Decode.succeed (GotoSlideNumber 5 0)
                else if k == "2"
                then Json.Decode.succeed (GotoSlideNumber 10 0)
                else if k == "3"
                then Json.Decode.succeed (GotoSlideNumber 15 0)
                else if k == "4"
                then Json.Decode.succeed (GotoSlideNumber 20 0)
                else if k == "5"
                then Json.Decode.succeed (GotoSlideNumber 25 0)
                else if k == "6"
                then Json.Decode.succeed (GotoSlideNumber 30 0)
                else if k == "7"
                then Json.Decode.succeed (GotoSlideNumber 35 0)
                else if k == "8"
                then Json.Decode.succeed (GotoSlideNumber 40 0)
                else if k == "9"
                then Json.Decode.succeed (GotoSlideNumber 45 0)
                else if k == "o"
                then Json.Decode.succeed ToggleOverviewMode
                else if k == "a"
                then Json.Decode.succeed TogglePrintMode
                else if k == "?"
                then Json.Decode.succeed ToggleHelpMode
                else Json.Decode.fail "Unknown key"
        )


position2slideN : List (Slide Msg) -> Int -> (Int, Int)
position2slideN slides p =
    let
        first_n : List (Slide Msg)
        first_n = List.take (p+1) slides
        acc : Slide Msg -> (Int, Int) -> (Int, Int)
        acc s (n, off) =
            if s.slideType == FirstSlideInGroup
            then (n+1, 0)
            else (n, off+1)
    in List.foldl acc (0, 0) first_n

findIx : SlideList Msg -> Int -> Int
findIx slides ix =
    case slides of
        [] -> 0
        (f::rest) ->
            if f.slideType == FirstSlideInGroup
            then
                if ix == 0
                then 0
                else 1 + (findIx rest (ix - 1))
            else 1 + findIx rest ix

update : SlideContent -> Msg -> Model -> ( Model, Cmd Msg )
update content msg model = case msg of
        NoMsg ->
            ( model, Cmd.none )
        NavTo s ->
            ( model, Nav.load s )
        GotoSlideNumber ix d ->
            let
                real_ix = d + findIx content.slides (ix - 1)
            in update content (GotoPosition real_ix) model
        PopToPosition p -> update content (GotoPosition p) { model | mode = SingleSlide }
        GotoPosition p ->
            let
                n = List.length content.slides
                real_p = clamp 0 (n-1) p
                (slide_n, slide_off) = position2slideN content.slides real_p
                m = Nav.replaceUrl model.key ("#"++String.fromInt slide_n ++ "." ++ String.fromInt slide_off)
            in ( {model | position = real_p}, m)
        NextSlide ->
            update content (GotoPosition <| advance1 content.slides model) model
        PreviousSlide ->
            update content (GotoPosition <| previous1 content.slides model) model
        LastSlide ->
            update content (GotoPosition (List.length content.slides - 1)) model
        FirstSlide ->
            update content (GotoPosition 0) model
        ToggleOverviewMode ->
            ( {model | mode = toggleOverviewMode model.mode}, Cmd.none )
        TogglePrintMode ->
            ( {model | mode = togglePrintMode model.mode }, Cmd.none )
        ToggleHelpMode ->
            ( {model | mode = toggleHelpMode model.mode }, Cmd.none )

toggleOverviewMode : Mode -> Mode
toggleOverviewMode m =
    if m == Overview
    then SingleSlide
    else Overview

togglePrintMode : Mode -> Mode
togglePrintMode m =
    if m == Print
    then SingleSlide
    else Print
toggleHelpMode : Mode -> Mode
toggleHelpMode m =
    if m == Help
    then SingleSlide
    else Help

advance1 : SlideList Msg -> Model -> Int
advance1 slides model =
    let n = model.position in
        if List.isEmpty <| List.drop (n+1) slides
            then n
            else n+1

previous1 : SlideList Msg -> Model -> Int
previous1 slides model =
    if model.position > 0
    then model.position - 1
    else 0

getSlide : Int -> SlideList Msg -> Slide Msg
getSlide n sl = case sl of
    (h :: rest) ->
        if n == 0
        then h
        else getSlide (n-1) rest
    _ -> slideErr

view : SlideContent -> Model -> Browser.Document Msg
view content model = case model.mode of
    SingleSlide -> viewSingleSlide content model
    Overview -> viewPaged content model
    Print -> viewPrint content model
    Help -> viewHelp content model

viewPaged : SlideContent -> Model -> Browser.Document Msg
viewPaged content model =
    { title = content.title
    , body = let
                v ix sl =
                    let
                        slides_per_row = 3
                        row = ix // slides_per_row
                        col = modBy slides_per_row ix
                        leftPos = String.fromInt (col * 420) ++ "px"
                        topPos = String.fromInt (row * 360) ++ "px"

                    in Html.div
                            [ HtmlAttr.style "left" leftPos
                            , HtmlAttr.style "top" topPos
                            , HtmlAttr.class "thumbnail"
                            , onClick (PopToPosition ix)
                            ]
                            [ sl.content ]
                in
                    [header
                    ,Html.div
                        [ HtmlAttr.style "width" "1920px"
                        , HtmlAttr.style "height" "1600px"
                        , HtmlAttr.style "position" "absolute"
                        , HtmlAttr.style "left" "-600px"
                        , HtmlAttr.style "top" "-400px"
                        ]
                        (List.indexedMap v content.slides)]
    }

viewPrint content model =
    { title = content.title
    , body =
        [ header
        , Html.div
            [HtmlAttr.id "main-content"
            ,HtmlAttr.class "print-mode"
            ]
            (List.map .content content.slides)
        , footer content model
        ]
    }

viewSingleSlide : SlideContent -> Model -> Browser.Document Msg
viewSingleSlide content model =
    let
        active : Slide Msg
        active = getSlide model.position content.slides
    in
    if active.slideType == Slides.Special
        then { title = content.title
            , body = [ Html.div [HtmlAttr.id "main-content"] [ active.content ] ]
        }
        else { title = content.title
            , body = [
                Html.div
                    [HtmlAttr.id "main-content"
                    ,onClick NextSlide
                    ]
                    [ header
                    , active.content
                    , footer content model
                    ]
                ]
            }

viewHelp content model =
    let
        base = viewSingleSlide content model
        helpOverlay =
            Html.div
                [HtmlAttr.id "overlay"]
                [HS.h1 "Help"
                ,HS.mdToHtml """
### Keys
- `J`/`N`/`ArrowRight`: next
- `K`/`P`/`ArrowLeft`: previous
- `O`: toggle overview mode
- `A`: toggle print mode (short for _All_)
- `?`: toggle help mode"""]
    in { base | body = helpOverlay :: base.body }


header : Html Msg
header =
    Html.node "link"
        [ HtmlAttr.rel "stylesheet"
        , HtmlAttr.href "/assets/style.css"
        ]
        []


footer : SlideContent -> Model -> Html Msg
footer content model =
    let
        countFirst sl =
            sl
            |> List.filter (\s -> s.slideType == FirstSlideInGroup)
            |> List.length
        cur = countFirst (List.take (model.position+1) content.slides)
        total = countFirst content.slides
    in
        content.mkFooter cur total

slideErr : Slide msg
slideErr =
    { content = Html.h1 [] [Html.text "internal error"]
    , slideType = FirstSlideInGroup }

onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest urlR = case urlR of
    Browser.External s -> NavTo s
    Browser.Internal u -> NavTo (Url.toString u)

onUrlChange : Url.Url -> Msg
onUrlChange u = NoMsg


