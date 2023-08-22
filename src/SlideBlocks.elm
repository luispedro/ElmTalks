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
        -- It simplifies the logic if the first block is never a All block
        firstFixed = case blocks of
            [] -> []
            (f :: rest) ->
                let
                    ff = case f.presence of
                        All -> { f | presence = NextStay }
                        _ -> f
                in (ff::rest)
        blockIndices n bs = case bs of
            [] -> []
            (h :: rest) -> case h.presence of
                All -> blockIndices n rest
                NextSingle -> n :: blockIndices (n + 1) rest
                NextStay -> n :: blockIndices (n + 1) rest
                In ixs -> ixs ++ blockIndices n rest
        total = case List.maximum <| blockIndices 0 firstFixed of
            Nothing -> 0
            Just m -> m + 1
        allBlocks = List.range 0 (total - 1)

        convertBlocks : Int -> List (SlideBlock msg) -> List ((List Int), List (Html msg))
        convertBlocks cur bs = case bs of
            [] -> []
            (h :: rest) -> case h.presence of
                All -> (allBlocks, h.body) :: convertBlocks cur rest
                NextSingle -> ([cur], h.body) :: convertBlocks (cur + 1) rest
                NextStay -> (List.range cur (total - 1), h.body) :: convertBlocks (cur + 1) rest
                In ixs -> (ixs, h.body) :: convertBlocks cur rest
        blocksTagged = convertBlocks 0 firstFixed
    in
        allBlocks
            |> List.map (\ix ->
                (blocksTagged
                    |> List.filterMap (\(ixs, body) ->
                        if List.member ix ixs then Just body else Nothing)
                    |> List.concat))
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
