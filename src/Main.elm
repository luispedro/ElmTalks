module Main exposing (..)

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Popover as Popover
import Bootstrap.Text as Text
import Bootstrap.Table as Table
import Bootstrap.Spinner as Spinner

import Html exposing (..)
import Html.Attributes as HtmlAttr
import Html.Events exposing (..)

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Url
import Json.Decode exposing (Decoder)

import Markdown


import Slides exposing (Slide, SlideType(..), SlideShow)
import Content exposing (slides, metadata)

{- The term `position` will refer to the internal counter (zero-based, indexes
 - into the slides list) and the term `slide number` will be the human readable
 - version (one-based, counts by groups)
 -}

type Mode = SingleSlide | Overview
type alias Model =
    { position : Int
    , key : Nav.Key
    , mode : Mode
    }


type Msg
    = NoMsg
    | NavTo String
    | GotoSlideNumber Int
    | GotoPosition Int
    | PopToPosition Int
    | NextSlide
    | PreviousSlide
    | LastSlide
    | FirstSlide
    | ToggleMode


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update slides
        , subscriptions = \_ -> Browser.Events.onKeyUp handleKeys
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init () u k =
    let
        islide = case u.fragment of
           Nothing -> 1
           Just f -> case String.toInt f of
                Just s -> s
                Nothing -> 1
    in update slides (GotoSlideNumber islide) { position = 0, key = k, mode = SingleSlide }

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
                then Json.Decode.succeed (GotoSlideNumber 1)
                else if k == "1"
                then Json.Decode.succeed (GotoSlideNumber 5)
                else if k == "2"
                then Json.Decode.succeed (GotoSlideNumber 10)
                else if k == "3"
                then Json.Decode.succeed (GotoSlideNumber 15)
                else if k == "4"
                then Json.Decode.succeed (GotoSlideNumber 20)
                else if k == "5"
                then Json.Decode.succeed (GotoSlideNumber 25)
                else if k == "6"
                then Json.Decode.succeed (GotoSlideNumber 30)
                else if k == "7"
                then Json.Decode.succeed (GotoSlideNumber 35)
                else if k == "8"
                then Json.Decode.succeed (GotoSlideNumber 40)
                else if k == "9"
                then Json.Decode.succeed (GotoSlideNumber 45)
                else if k == "o"
                then Json.Decode.succeed ToggleMode
                else Json.Decode.fail "Unknown key"
        )


position2slideN : List (Slide Msg) -> Int -> Int
position2slideN slides p =
    List.take (p+1) slides
        |> List.filter (\s -> s.slideType == FirstSlideInGroup)
        |> List.length

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

update : List (Slide Msg) -> Msg -> Model -> ( Model, Cmd Msg )
update slides msg model = case msg of
        NoMsg ->
            ( model, Cmd.none )
        NavTo s ->
            ( model, Nav.load s )
        GotoSlideNumber ix ->
            let
                real_ix = findIx slides (ix - 1)
            in update slides (GotoPosition real_ix) model
        PopToPosition p -> update slides (GotoPosition p) { model | mode = SingleSlide }
        GotoPosition p ->
            let
                n = List.length slides
                real_p =
                    if p < 0
                    then 0
                    else if p >= n
                    then n - 1
                    else p
                slide_n = position2slideN slides real_p
                m = Nav.replaceUrl model.key ("#"++String.fromInt slide_n)
            in ( {model | position = real_p}, m)
        NextSlide ->
            update slides (GotoPosition <| advance1 model) model
        PreviousSlide ->
            update slides (GotoPosition <| previous1 model) model
        LastSlide ->
            update slides (GotoPosition (List.length slides - 1)) model
        FirstSlide ->
            update slides (GotoPosition 0) model
        ToggleMode ->
            ( {model | mode = toggleMode model.mode}, Cmd.none )

toggleMode : Mode -> Mode
toggleMode m =
    case m of
        SingleSlide -> Overview
        Overview -> SingleSlide

advance1 : Model -> Int
advance1 model =
    let n = model.position in
        if n + 1 >= List.length slides
            then n
            else n+1

previous1 : Model -> Int
previous1 model =
    if model.position > 0
    then model.position - 1
    else 0

getSlide : Int -> SlideShow msg -> Slide msg
getSlide n sl = case sl of
    (h :: rest) ->
        if n == 0
        then h
        else getSlide (n-1) rest
    _ -> slideErr

view model = case model.mode of
    SingleSlide -> viewSingleSlide model
    Overview -> viewPaged model

viewPaged model =
    { title = metadata.title
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
                        , HtmlAttr.style "top" "-600px"
                        ]
                        (List.indexedMap v slides)]
    }

viewSingleSlide model =
    let
        active : Slide msg
        active = getSlide model.position slides
    in
    if active.slideType == Slides.Special
        then { title = metadata.title
            , body = [ Html.div [HtmlAttr.id "main-content"] [ active.content ] ]
        }
        else { title = metadata.title
            , body = [
                Html.div
                    [HtmlAttr.id "main-content"]
                    [ header
                    , active.content
                    , footer model
                    ]
                ]
            }


header : Html Msg
header =
    node "link"
        [ HtmlAttr.rel "stylesheet"
        , HtmlAttr.href "/assets/style.css"
        ]
        []


footer : Model -> Html Msg
footer model =
    let
        countFirst sl =
            sl
            |> List.filter (\s -> s.slideType == FirstSlideInGroup)
            |> List.length
        cur = countFirst (List.take (model.position+1) slides)
        total = countFirst slides
    in
        Html.div
            [HtmlAttr.id "footer"]
            [Html.p []
                [Html.strong []
                    [Html.text "Luis Pedro Coelho"]
                ,Html.img
                    [HtmlAttr.src "/Media/twitter.png"
                    ,HtmlAttr.style "width" "28px"
                    ,HtmlAttr.style "margin-bottom" "-8px"
                    ,HtmlAttr.style "margin-left" "20px"
                    ,HtmlAttr.style "margin-right" "-4px"
                    ]
                    []
                ,Html.text "@luispedrocoelho"
                ,Html.span [HtmlAttr.style "padding-right" "42em"] []

                ,Html.text metadata.shortTitle
                ,Html.text " ["
                ,Html.text (String.fromInt cur)
                ,Html.text "/"
                ,Html.text (String.fromInt total)
                ,Html.text "]"
                ]
            ]


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


