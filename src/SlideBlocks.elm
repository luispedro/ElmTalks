module SlideBlocks exposing
    ( mkBlockedSlide
    , nextFragment
    , nextFragmentStay
    , allFragments
    , someFragments
    )

import Html exposing (Html)
import Slides

type SlidePresence =
    All
    | NextSingle
    | NextStay
    | In (List Int)

type alias SlideBlock msg =
    { presence : SlidePresence
    , body : List (Html msg)
    }


mkBlockedSlide : String -> List (SlideBlock msg) -> Slides.RawSlide msg
mkBlockedSlide title blocks =
    let
        countBlocks n bs = case bs of
            [] -> n
            (h :: rest) -> case h.presence of
                All -> countBlocks n rest
                NextSingle -> countBlocks (n + 1) rest
                NextStay -> countBlocks (n + 1) rest
                In ixs -> case List.maximum (n::ixs) of
                    Nothing -> countBlocks n rest
                    Just m -> countBlocks m rest
        total = 1 + countBlocks 0 blocks
        allBlocks = List.range 0 (total - 1)

        convertBlocks : Int -> List (SlideBlock msg) -> List ((List Int), List (Html msg))
        convertBlocks cur bs = case bs of
            [] -> []
            (h :: rest) -> case h.presence of
                All -> (allBlocks, h.body) :: convertBlocks cur rest
                NextSingle -> ([cur], h.body) :: convertBlocks (cur + 1) rest
                NextStay -> (List.range cur (total - 1), h.body) :: convertBlocks (cur + 1) rest
                In ixs -> (ixs, h.body) :: convertBlocks cur rest
        blocksTagged = convertBlocks 0 blocks
    in
        allBlocks
            |> List.map (\ix ->
                (List.concat <| List.filterMap (\(ixs, body) ->
                        if List.member ix ixs then Just body else Nothing) blocksTagged))
            |> Slides.mkSteppedSlide title


nextFragment : List (Html msg) -> SlideBlock msg
nextFragment body =
    { presence = NextSingle
    , body = body
    }

nextFragmentStay : List (Html msg) -> SlideBlock msg
nextFragmentStay body =
    { presence = NextStay
    , body = body
    }

allFragments : List (Html msg) -> SlideBlock msg
allFragments body =
    { presence = All
    , body = body
    }

someFragments : List Int -> List (Html msg) -> SlideBlock msg
someFragments ixs body =
    { presence = In ixs
    , body = body
    }
