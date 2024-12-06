module HtmlSimple exposing
        ( floatLeftDiv
        , floatRightDiv
        , floatClear

        , textOL
        , textUL

        , img80
        , img50
        , imgw

        , p
        , h1
        , h2
        , h3
        , textA

        , underline
        , padTop1

        , mdToHtml
        )

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (..)
import Markdown


floatLeftDiv : String -> List (Html msg) -> Html msg
floatLeftDiv = floatRLDiv "left"

floatRightDiv : String -> List (Html msg) -> Html msg
floatRightDiv = floatRLDiv "right"

floatRLDiv : String -> String -> List (Html msg) -> Html msg
floatRLDiv dir w content =
    Html.div
        [HtmlAttr.style "float" dir
        ,HtmlAttr.style "width" w
        ,HtmlAttr.class "simple-float"]
        content

floatClear : Html msg
floatClear =
    Html.div
        [HtmlAttr.style "clear" "both"]
        []

textUL : List String -> Html msg
textUL = Html.ul [] << List.map (Html.li [] << List.singleton << Html.text)

textOL : List String -> Html msg
textOL = Html.ol [] << List.map (Html.li [] << List.singleton << Html.text)


img50 = imgw "50%"
img80 = imgw "80%"

addStartingSlash s =
    if String.left 6 s == "Media/"
    then "/" ++ s
    else s

imgw w src =
        Html.img
            [HtmlAttr.src (addStartingSlash src)
            ,HtmlAttr.style "width" w]
            []
p t = Html.p [] [Html.text t]
h1 t = Html.h1 [] [Html.text t]
h2 t = Html.h2 [] [Html.text t]
h3 t = Html.h3 [] [Html.text t]


textA url t = Html.a [HtmlAttr.href url] [Html.text t]

underline = HtmlAttr.style "text-decoration" "underline"
padTop1 = HtmlAttr.style "padding-top" "1em"

markdownOptions =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }
mdToHtml = Markdown.toHtmlWith markdownOptions []

