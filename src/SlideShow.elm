port module SlideShow exposing (mkSlideShow, ProgramType)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (onClick)

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Url
import Json.Decode exposing (Decoder)
import Task
import Time

import HtmlSimple as HS

import Slides exposing (Slide, SlideType(..), SlideList)

{- The term `position` will refer to the internal counter (zero-based, indexes
 - into the slides list) and the term `slide number` will be the human readable
 - version (one-based, counts by groups).
 -
 - The URL fragment encodes both the window role and the current location:
 -     #N     or #N.O      -- audience view, slide N (optional offset O)
 -     #s/N   or #s/N.O    -- speaker view, slide N (optional offset O)
 -}

port broadcastPosition : Int -> Cmd msg
port receivePosition : (Int -> msg) -> Sub msg
port openSpeakerWindow : () -> Cmd msg


type Mode = SingleSlide | Overview | Print | Help
type WindowRole = Audience | Speaker

type alias Model =
    { position : Int
    , key : Nav.Key
    , mode : Mode
    , role : WindowRole
    , timerStart : Time.Posix
    , now : Time.Posix
    }


type Msg
    = NoMsg
    | NavTo String
    | GotoSlideNumber Int Int
    | GotoPosition Int
    | RemoteGotoPosition Int
    | PopToPosition Int
    | NextSlide
    | PreviousSlide
    | LastSlide
    | FirstSlide
    | ToggleOverviewMode
    | TogglePrintMode
    | ToggleHelpMode
    | OpenSpeaker
    | Tick Time.Posix
    | InitTime Time.Posix
    | ResetTimer


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
        , subscriptions = subscriptions
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        base =
            [ Browser.Events.onKeyUp handleKeys
            , receivePosition RemoteGotoPosition
            ]
        timer = case model.role of
            Speaker -> [ Time.every 1000 Tick ]
            Audience -> []
    in Sub.batch (base ++ timer)


parseFragment : Maybe String -> ( WindowRole, Int, Int )
parseFragment mf = case mf of
    Nothing -> (Audience, 1, 0)
    Just f ->
        let
            (role, rest) =
                if String.startsWith "s/" f
                then (Speaker, String.dropLeft 2 f)
                else (Audience, f)
            (i, o) = case String.split "." rest of
                [s] -> case String.toInt s of
                    Just n -> (n, 0)
                    Nothing -> (1, 0)
                [s, ofs] -> case (String.toInt s, String.toInt ofs) of
                    (Just n, Just on) -> (n, on)
                    _ -> (1, 0)
                _ -> (1, 0)
        in (role, i, o)


init : SlideContent -> () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init content () u k =
    let
        (role, islide, off) = parseFragment u.fragment
        epoch = Time.millisToPosix 0
        model0 =
            { position = 0
            , key = k
            , mode = SingleSlide
            , role = role
            , timerStart = epoch
            , now = epoch
            }
        (model1, cmd1) = update content (GotoSlideNumber islide off) model0
        initTimeCmd = Task.perform InitTime Time.now
    in ( model1, Cmd.batch [cmd1, initTimeCmd] )


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
                else if k == "s" || k == "S"
                then Json.Decode.succeed OpenSpeaker
                else if k == "r" || k == "R"
                then Json.Decode.succeed ResetTimer
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


fragmentFor : WindowRole -> Int -> Int -> String
fragmentFor role slide_n slide_off =
    let
        prefix = case role of
            Speaker -> "#s/"
            Audience -> "#"
    in prefix ++ String.fromInt slide_n ++ "." ++ String.fromInt slide_off


setPosition : SlideContent -> Bool -> Int -> Model -> ( Model, Cmd Msg )
setPosition content broadcast p model =
    let
        n = List.length content.slides
        real_p = clamp 0 (n-1) p
        (slide_n, slide_off) = position2slideN content.slides real_p
        urlCmd = Nav.replaceUrl model.key (fragmentFor model.role slide_n slide_off)
        broadcastCmd =
            if broadcast && real_p /= model.position
            then broadcastPosition real_p
            else Cmd.none
    in ( {model | position = real_p}, Cmd.batch [urlCmd, broadcastCmd] )


update : SlideContent -> Msg -> Model -> ( Model, Cmd Msg )
update content msg model = case msg of
        NoMsg ->
            ( model, Cmd.none )
        NavTo s ->
            ( model, Nav.load s )
        GotoSlideNumber ix d ->
            let
                real_ix = d + findIx content.slides (ix - 1)
            in setPosition content True real_ix model
        PopToPosition p ->
            setPosition content True p { model | mode = SingleSlide }
        GotoPosition p ->
            setPosition content True p model
        RemoteGotoPosition p ->
            setPosition content False p model
        NextSlide ->
            setPosition content True (advance1 content.slides model) model
        PreviousSlide ->
            setPosition content True (previous1 content.slides model) model
        LastSlide ->
            setPosition content True (List.length content.slides - 1) model
        FirstSlide ->
            setPosition content True 0 model
        ToggleOverviewMode ->
            ( {model | mode = toggleOverviewMode model.mode}, Cmd.none )
        TogglePrintMode ->
            ( {model | mode = togglePrintMode model.mode }, Cmd.none )
        ToggleHelpMode ->
            ( {model | mode = toggleHelpMode model.mode }, Cmd.none )
        OpenSpeaker -> case model.role of
            Audience -> ( model, openSpeakerWindow () )
            Speaker -> ( model, Cmd.none )
        Tick t ->
            ( {model | now = t}, Cmd.none )
        InitTime t ->
            ( {model | now = t, timerStart = t}, Cmd.none )
        ResetTimer ->
            ( {model | timerStart = model.now}, Cmd.none )


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

getSlideMaybe : Int -> SlideList Msg -> Maybe (Slide Msg)
getSlideMaybe n sl =
    if n < 0
    then Nothing
    else case sl of
        [] -> Nothing
        (h :: rest) ->
            if n == 0
            then Just h
            else getSlideMaybe (n-1) rest

view : SlideContent -> Model -> Browser.Document Msg
view content model = case model.role of
    Speaker -> viewSpeaker content model
    Audience -> case model.mode of
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


viewSpeaker : SlideContent -> Model -> Browser.Document Msg
viewSpeaker content model =
    let
        active = getSlide model.position content.slides
        next1 = getSlideMaybe (model.position + 1) content.slides
        next2 = getSlideMaybe (model.position + 2) content.slides
        previewBox label mslide =
            Html.div
                [HtmlAttr.class "speaker-preview"]
                [ Html.div [HtmlAttr.class "speaker-preview-label"] [Html.text label]
                , Html.div [HtmlAttr.class "speaker-preview-frame"]
                    [ case mslide of
                        Just s -> s.content
                        Nothing -> Html.div [HtmlAttr.class "speaker-empty"] [Html.text "(end)"]
                    ]
                ]
        countFirst sl =
            sl
            |> List.filter (\s -> s.slideType == FirstSlideInGroup)
            |> List.length
        cur = countFirst (List.take (model.position+1) content.slides)
        total = countFirst content.slides
        elapsedMs =
            Time.posixToMillis model.now - Time.posixToMillis model.timerStart
        elapsedSec = max 0 (elapsedMs // 1000)
        mm = elapsedSec // 60
        ss = modBy 60 elapsedSec
        pad2 i =
            if i < 10
            then "0" ++ String.fromInt i
            else String.fromInt i
        timerText = pad2 mm ++ ":" ++ pad2 ss
    in
    { title = "Speaker — " ++ content.title
    , body =
        [ header
        , Html.div
            [HtmlAttr.class "speaker-view"]
            [ Html.div
                [HtmlAttr.class "speaker-current"]
                [ Html.div [HtmlAttr.class "speaker-current-frame"]
                    [ active.content ]
                ]
            , Html.div
                [HtmlAttr.class "speaker-side"]
                [ previewBox "Next" next1
                , previewBox "After" next2
                ]
            , Html.div
                [HtmlAttr.class "speaker-footer"]
                [ Html.span [HtmlAttr.class "speaker-counter"]
                    [Html.text (String.fromInt cur ++ " / " ++ String.fromInt total)]
                , Html.span [HtmlAttr.class "speaker-timer"]
                    [Html.text timerText]
                , Html.button
                    [HtmlAttr.class "speaker-reset"
                    ,onClick ResetTimer
                    ]
                    [Html.text "Reset"]
                ]
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
- `S`: open speaker view in a new window
- `R`: reset elapsed-time timer (speaker view)
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

