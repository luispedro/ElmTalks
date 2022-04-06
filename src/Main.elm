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
import Json.Decode exposing (Decoder)

import Markdown


import Slides exposing (Slide, SlideType(..), SlideShow)
import Content exposing (slides)

type alias SlidePosition = Int

type Model = Showing SlidePosition

type Msg
    = NoMsg
    | GotoSlide Int
    | NextSlide
    | PreviousSlide
    | LastSlide
    | FirstSlide


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update slides
        , subscriptions = \_ -> Browser.Events.onKeyUp handleKeys
        }

init : () -> ( Model, Cmd Msg )
init () =
    ( Showing 0
    , Cmd.none
    )

handleKeys : Decoder Msg
handleKeys =
    Json.Decode.string
        |> Json.Decode.field "key"
        |> Json.Decode.andThen (\k ->
                if List.member k [" ", "n", "N", "j", "J", "ArrowLeft"]
                then Json.Decode.succeed NextSlide
                else if List.member k ["p", "P", "k", "K", "ArrowRight"]
                then Json.Decode.succeed PreviousSlide
                else if List.member k ["f", "F", "h", "H"]
                then Json.Decode.succeed FirstSlide
                else if List.member k ["l", "L"]
                then Json.Decode.succeed LastSlide
                else if k == "0"
                then Json.Decode.succeed (GotoSlide 0)
                else if k == "1"
                then Json.Decode.succeed (GotoSlide 5)
                else if k == "2"
                then Json.Decode.succeed (GotoSlide 10)
                else if k == "3"
                then Json.Decode.succeed (GotoSlide 15)
                else if k == "4"
                then Json.Decode.succeed (GotoSlide 20)
                else if k == "5"
                then Json.Decode.succeed (GotoSlide 25)
                else if k == "6"
                then Json.Decode.succeed (GotoSlide 30)
                else if k == "7"
                then Json.Decode.succeed (GotoSlide 35)
                else if k == "8"
                then Json.Decode.succeed (GotoSlide 40)
                else if k == "9"
                then Json.Decode.succeed (GotoSlide 45)
                else Json.Decode.fail ""
        )


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
        GotoSlide ix ->
            let
                real_ix = findIx slides (ix - 1)
                n = List.length slides
            in ( Showing (if real_ix < n then real_ix else n - 1), Cmd.none )
        NextSlide ->
            ( advance1 model, Cmd.none )
        PreviousSlide ->
            ( previous1 model, Cmd.none )
        LastSlide ->
            (Showing (List.length slides - 1), Cmd.none)
        FirstSlide ->
            (Showing 0, Cmd.none)

advance1 : Model -> Model
advance1 (Showing n) =
    if n + 1 >= List.length slides
    then Showing n
    else Showing (n+1)

previous1 : Model -> Model
previous1 (Showing n) =
    if n > 0
    then Showing (n-1)
    else Showing n

getSlide : Model -> SlideShow msg -> Slide msg
getSlide (Showing n) sl = case sl of
    (h :: rest) ->
        if n == 0
        then h
        else getSlide (Showing (n-1)) rest
    _ -> slideErr

view model =
    let
        active : Slide msg
        active = getSlide model slides
    in { title = "Microbes & antimicrobes"
        , body = [
            header,
            active.content,
            footer model]
        }


header : Html Msg
header =
    node "link"
        [ HtmlAttr.rel "stylesheet"
        , HtmlAttr.href "/assets/style.css"
        ]
        []


footer : Model -> Html Msg
footer (Showing pos) =
    let
        countFirst sl =
            sl
            |> List.filter (\s -> s.slideType == FirstSlideInGroup)
            |> List.length
        cur = countFirst (List.take (pos+1) slides)
        total = countFirst slides
    in
        Html.div
            [HtmlAttr.id "footer"]
            [Html.p []
                [Html.strong [HtmlAttr.style "padding-right" "42em"]
                    [Html.text "Luis Pedro Coelho"]
                ,Html.text "Microbes and antimicrobes ["
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


markdownOptions =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }
mdToHtml = Markdown.toHtmlWith markdownOptions []

