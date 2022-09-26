module HtmlSimple exposing (floatLeftDiv, floatRightDiv, floatClear, textUL)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (..)

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

