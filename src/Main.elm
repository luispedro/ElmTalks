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


import Slides exposing (Slide, SlideShow, slides)

type alias SlidePosition = Int

type Model = Showing SlidePosition

type Msg
    = NoMsg
    | NextSlide
    | PreviousSlide
    | LastSlide
    | FirstSlide


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
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
        |> Json.Decode.andThen (\ks ->
            let
                k = case String.toList ks of
                    (h :: _) -> h
                    _ -> '?'
            in
                if List.member k (String.toList "nNjJ")
                then Json.Decode.succeed NextSlide
                else if List.member k (String.toList "pPkK")
                then Json.Decode.succeed PreviousSlide
                else if List.member k (String.toList "fFhH")
                then Json.Decode.succeed FirstSlide
                else if List.member k (String.toList "lL")
                then Json.Decode.succeed LastSlide
                else Json.Decode.fail ""
        )



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = case msg of
        NoMsg ->
            ( model, Cmd.none )
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
            active,
            footer model]
        }


header : Html Msg
header =
    Grid.simpleRow
        [
        ]


footer : Model -> Html Msg
footer (Showing cur) =
    let
        total = List.length slides
    in
        Html.div
            [HtmlAttr.class "footer"]
            [Html.text "Microbes and antimicrobes of the global microbiome ("
            ,Html.text (String.fromInt (cur+1))
            ,Html.text "/"
            ,Html.text (String.fromInt total)
            ,Html.text ")"
            ]


slideErr : Slide msg
slideErr = Html.h1 [] [Html.text "internal error"]


markdownOptions =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }
mdToHtml = Markdown.toHtmlWith markdownOptions []

