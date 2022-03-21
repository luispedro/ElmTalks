module Slides exposing (Slide, SlideType(..), SlideShow, slides)

import Html exposing (..)
import Html.Attributes as HtmlAttr
import Html.Events exposing (..)

import Chart as C
import Svg as S
import Chart.Attributes as CA

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Json.Decode exposing (Decoder)

import Markdown

type SlideType = FirstSlideInGroup | Follower

type alias Slide msg =
    { content : Html msg
    , slideType : SlideType
    }
type alias SlideShow msg = List (Slide msg)


mkSlide : String -> List (Html msg) -> Slide msg
mkSlide title body =
    { content = Html.div
        [HtmlAttr.class "slide"]
        (Html.h2 [] [Html.text title] :: body)
    , slideType = FirstSlideInGroup
    }


tagSlideGroup : List (Slide msg) -> List (Slide msg)
tagSlideGroup sl = case sl of
    [] -> []
    (h :: rest) -> h :: List.map (\s -> { s | slideType = Follower }) rest

mkIncrementalSlide : String -> List (List (Html msg)) -> List (Slide msg)
mkIncrementalSlide title parts =
    List.range 1 (List.length parts)
    |> List.map (\ix ->
            mkSlide title (List.concat (List.take ix parts)))
    |> tagSlideGroup

markdownOptions =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }
mdToHtml = Markdown.toHtmlWith markdownOptions []

img80 src =
    Html.div
        [HtmlAttr.style "text-align" "center"]
        [Html.img
            [HtmlAttr.src src
            ,HtmlAttr.style "width" "80%"]
            []
        ]

p t = Html.p [] [Html.text t]




------------------------------------------



slides = List.concat
    [
    intro
    ,historical
    ,gmgcv1slides
    ,newFamiliesSlides
    ,semiBin
    ,gmgcv2
    ,ampSlides
    ,summary
    ]


intro =
    [{ content = Html.div [HtmlAttr.class "slide"]
        [Html.h1 []
            [Html.text "A global view of microbes & anti-microbes"]
        ,Html.h2
            [HtmlAttr.style "padding-top" "1em"
            ,HtmlAttr.style "padding-bottom" "0px"
            ,HtmlAttr.style "margin-bottom" "0px"
            ,HtmlAttr.style "color" "#7570b3"
            ]
            [Html.text "Luis Pedro Coelho"]
        ,Html.p
            [HtmlAttr.style "padding-bottom" "0px"
            ,HtmlAttr.style "margin" "0px"
            ]
            [Html.text "luispedro@big-data-biology.org"
            ,Html.br [] []
            ,Html.img
                [HtmlAttr.src "/Media/twitter.png"
                ,HtmlAttr.style "width" "28px"
                ,HtmlAttr.style "margin-bottom" "-8px"
                ,HtmlAttr.style "margin-right" "8px"]
                []
            ,Html.text "@luispedrocoelho"]
            ,Html.p [ HtmlAttr.style "text-align" "right"
                    , HtmlAttr.style "padding-top" "9em" ]
                    [ Html.img [ HtmlAttr.src "Media/ISTBI-logo.png"
                                , HtmlAttr.style "width" "66%"
                                , HtmlAttr.style "padding-right" "4em" ]
                        []
                    , Html.img [ HtmlAttr.src "Media/Fudan-logo.png", HtmlAttr.style "width" "18%" ]
                        []
                    ]
        ]
     ,slideType = FirstSlideInGroup }
    ,mkSlide "BDB-Lab (Big Data Biology Lab) high-level overview"
        [img80 "/Media/BigDataBiology/BDB-Lab_structure2.svg"]
    ]


gmgcv1slides =
    [
        mkSlide "The global microbiome"
            [img80 "/Media/GMGC/Fig1a-layered.svg"
            ,Html.p [HtmlAttr.style "padding-top" "0em"]
                    [Html.text "Coelho "
                    ,Html.em [] [Html.text "et al."]
                    ,Html.text ", Nature, 2022"]
            ]
        ,mkSlide "The global microbiome"
            [mdToHtml """
- Human gut (&gt;7,000 samples, many projects).</li>
- Mouse gut (230 samples, <a href="" class="citation">Xiao et al., Nat Biotech, 2015</a>).</li>
- Pig gut (195 <a href="" class="citation">Xiao et al., Nat Micro, 2016</a>)
- Dog gut (129 samples, <a href="" class="citation">Coelho et al., Microbiome, 2018</a>)
- Kittens gut (124 samples,
    <a href="https://dx.plos.org/10.1371/journal.pone.0101021" class="citation">Deusch et al., PlOS One, 2014</a>;
    <a href="https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0144881" class="citation">Deusch et al., PlOS One, 2015</a>
    )
- Marine environment (130 samples, <a href="" class="citation">Sunagawa, Coelho, Chaffon et al., 2015</a>)
- Built-environment (1295 samples, <a href="" class="citation">MetaSUB consortium</a>)
- ...

Reworked data from scratch _using a consistent methodology_
"""]
        ,mkSlide "We also have 46,655 MAGs, but they miss many genes"
            [img80 "/Media/GMGC/Bork_EDfig4.png"
            ,mdToHtml """
This includes 75,674 <em>medium-quality</em> bins (for a total of 122k high- or medium-quality bins)
"""]
        ,mkSlide "Only a few genes are shared between environments (multi-habitat genes)"
            [img80 "/Media/GMGC/gene-flow.svg.png"
            ,p "Little sharing overall, but concentrated on the mammalian guts"
            ]

        ,mkSlide "Genes are shared between similar environments"
            [img80 "/Media/GMGC/mammal-flow.svg"
            ,p "Little sharing overall, but concentrated on the mammalian guts"
            ]


        ,mkSlide "AMR genes are more likely to be present in multiple habitats"
            [img80 "/Media/GMGC/all-habitats-mobility.svg"
            ,p "There are millions of genes represented in each bar, all comparisons are highly significant"
            ]

        ,mkSlide "There is a habitat signature"
            [img80 "/Media/GMGC/submission.2020.04/Figure4-densities-per-species.svg"
            ,p "Frankly, I'm still not sure what is going on here"
            ]

        ,mkSlide "The environmental patterns are a mixture of subpatterns"
            [img80 "/Media/GMGC/Habitat-subpatterns-horizontal.svg"
            ,p "Environmental samples are a mixture of sub-habitats"
            ]
        ,mkSlide "Most of these genes belong to a small number of gene families"
            [img80 "/Media/GMGC/submission.2020.04/Figure2-gf-sizes.svg"
            ]

        ,mkSlide "Most genes are rare"
            [img80 "/Media/GMGC/submission.2020.04/Figure5-rare.svg"
            ,mdToHtml "This is what is predicted by _models of (nearly-)neutral evolution_"]

        ,mkSlide "Most genes and rare ones, in particular, are not under selection"
            [img80 "/Media/GMGC/Figure6-selection_horizontal.svg"
            ,p "At different levels"
            ,Html.ul []
                [Html.li [] [Html.text " Low levels of selection"]
                ,Html.li [] [Html.text " Increased selection for more prevalent genes"]]
            ]
        ,mkSlide "GMGC as a resource"
            [img80 "/Media/GMGC/GMGC_EMBL_DE_search.png"
            ,mdToHtml "[https://gmgc.embl.de/](https://gmgc.embl.de/)"
            ]
    ]

newFamiliesSlides =
    [mkSlide "Novel protein families"
        [img80 "/Media/NovelProteins/Figure1a.svg"
        ,Html.p []
            [Html.a
                [HtmlAttr.href "https://www.biorxiv.org/content/10.1101/2022.01.26.477801v1"]
            [Html.text "(Rodríguez del Río, et al., BioRxiv, 2022)"]]]
    ,mkSlide "Novel protein families"
        [img80 "/Media/NovelProteins/Figure3a.svg"]

    ,mkSlide "Novel protein families"
        [img80 "/Media/NovelProteins/Figure3bc.svg"
        ,mdToHtml """
- Novel families are ubiquitous (often in multiple habitats—unlike unigenes, but this could be an effect of selection)
- Highly conserved (but mostly still unknown molecular function)
"""
        ,Html.div
            [HtmlAttr.style "text-align" "left"]
            [personImage "Jaime Huerta-Cepas"
                        "/Media/NovelProteins/JaimeHuertaCepas.jpg"
            ,personImage "Alvaro del Río"
                        "/Media/NovelProteins/AlvaroDelRio.jpeg"
            ]
        ]
    ]

personImage name pic =
    Html.div
        [HtmlAttr.style "float" "right"
        ,HtmlAttr.style "max-width" "220px"
        ,HtmlAttr.style "padding-right" "4em"
        ]
        [Html.img
            [HtmlAttr.src pic
            ,HtmlAttr.style "max-width" "200px"]
            []
        ,Html.br [] []
        ,Html.text name]

gmgcv2 = List.concat
    [mkIncrementalSlide "The future of GMGC I: More data"
        [
            [p "So far, I showed published work. What's next?"]
            ,[img80 "/Media/GMGCv2/GMGCv2.map.png"]
        ]
    ,buildGMGCv2

    ,mkIncrementalSlide "The future of GMGC II: Smaller peptides"
        [

            [mdToHtml """In the work I showed you before, we ignored any
            sequences that were _too small_, namely those under 32 amino-acids. We are currently looking into those!"""]
            ,[mdToHtml """
### Small genes are not just smaller

- Hard to predict
- Hard to assign function by homology
- Modules, families harder to predict
- Evolutionary signals harder to identify
"""]
            ,[mdToHtml """
### First target: antimicrobial peptides (AMPs)

1. short peptides (≤ 100 amino acids)
2. antimicrobial

AMPs are already widely used in industrial applications (less so clinically)
"""
            ,personImage "Yiqian Duan" "/Media/BigDataBiology/people/YiqianDuan.jpg"
            ,personImage "Célio Dias Santos-Júnior"
                    "/Media/BigDataBiology/people/CelioDiasSantosJunior.jpg"
            ]

        ]
    ]
ampSlides =
    [mkSlide "Macrel"
        [img80 "/Media/macrel/2020-04/Fig1_touched.svg"
        ,Html.br [] []
        ,Html.p []
            [Html.a [HtmlAttr.href "https://peerj.com/articles/10555/"]
            [Html.text "(Dias Santos-Junior, et al., 2020)"
            ,Html.span [HtmlAttr.style "padding-left" "4em"]
                [Html.a [HtmlAttr.href "https://big-data-biology.org/software/macrel"]
                    [Html.text "https://big-data-biology.org/software/macrel"]
                ]]
            ]
        ]
    ,mkSlide "Evaluation against standard benchmarks"
        [img80 "/Media/macrel/Table_performance.png"
        ]
    ,mkSlide "We identify >40m high-quality putative small proteins"
        [img80 "/Media/GMSC/GMSC_qc.svg"
        ,p "We are currently exploring this resource"]
    ,mkSlide "The AMPSphere: almost one million AMP candidates"
        [img80 "/Media/AMPsphere/Fig1.png"]
    ]

buildGMGCv2 : List (Slide msg)
buildGMGCv2 =
    List.range 1 16
    |> List.map (\ix ->
            mkSlide "Building GMGCv2 (WIP)"
                [img80 (String.concat
                            ["/Media/GMGCv2/GMGCv2_status"
                            ,String.fromInt ix
                            ,".png"])
                ])
    |> tagSlideGroup

ampCatalogBuild : List (Slide msg)
ampCatalogBuild =
    List.range 0 9
    |> List.map (\ix ->
            mkSlide "Building a catalog of AMPs"
                [img80 (String.concat
                            ["/Media/AMPsphere/creation/frame"
                            ,String.fromInt ix
                            ,".png"])
                ,p "We are applying the same general approach as GMGC: process all (meta)genomes with a consistent methodology"
                ])
    |> tagSlideGroup


semiBin : List (Slide msg)
semiBin =
    (mkIncrementalSlide "Binning: the problem of building genes from contigs"
        [[Html.div
            [HtmlAttr.style "float" "left"
            ,HtmlAttr.style "width" "36%"]
            [Html.img
                [HtmlAttr.src "/Media/SemiBin/binning.png"
                ,HtmlAttr.style "height" "600px"
                ] []
            ,mdToHtml "Image from [Software Carpentry](https://carpentries-incubator.github.io/metagenomics/05-binning/index.html)"
            ]]
        ,[mdToHtml """
### Reference-based solutions (supervised)

- Assigns contigs to known species
- Reliable
- Cannot learn new species

### _De novo_ (unsupervised)

- Attempts to _infer_ bins
- More errors
- Can learn new species

"""]
        ,[mdToHtml """
### Our proposal: semi-supervised

- Uses reference
- Can learn **new** species
"""
        ,personImage "Shaojun Pan" "/Media/BigDataBiology/people/ShaojunPan.jpg"]
    ]) ++
    (mkIncrementalSlide "SemiBin: using deep learning outperforms state-of-the-art"
        [[Html.div
            [HtmlAttr.style "float" "left"
            ,HtmlAttr.style "padding-right" "4em"
            ]
            [
                Html.img
                [HtmlAttr.src "/Media/SemiBin/Fig3b.svg"
                ,HtmlAttr.style "height" "680px"
                ] []
            ]
        ]
        ,[Html.div
            []
            [Html.img
                [HtmlAttr.src "/Media/SemiBin/Supp16a.svg"
                ,HtmlAttr.style "height" "680px"]
                []
            ]
        ]]) ++
    [mkSlide "SemiBin works across many habitats"
        [img80 "/Media/SemiBin/Fig5.svg"
        ,Html.p
            []
            [Html.em [] [Html.text "Similar"]
            ,Html.text " environments behave similarly"
            ,Html.span [HtmlAttr.style "padding-left" "24em"]
                [Html.a [HtmlAttr.href "https://www.biorxiv.org/content/10.1101/2021.08.16.456517v1.full"]
                    [Html.text "(Pan el al., Nat Comms, "
                    ,Html.cite [] [Html.text "Accepted in principle"
                    ,Html.text ")"]
                    ]
                ]
            ]
        ]
    ] ++
    (mkIncrementalSlide "A little side-story: simulated data can be misleading"
        [
            [Html.div []
                [mdToHtml """
SemiBin relies on **contig classification**

Which is the best system?

1. CAT (which uses the NCBI taxonomy)
2. mmseqs2 (using the GTDB)
"""]]
        ,[Html.div
            [HtmlAttr.style "padding" "1em"
            ,HtmlAttr.style "float" "left"
            ]
            [Html.img
                [HtmlAttr.src "/Media/SemiBin/Supp19a.svg"
                ,HtmlAttr.style "height" "400px"]
                []]]
        ,[Html.img
                [HtmlAttr.src "/Media/SemiBin/Supp19b.svg"
                ,HtmlAttr.style "height" "400px"]
                []]
        ,[Html.div
            [HtmlAttr.style "clear" "both"]
            [p "Simulated data can be misleading"]]
        ]) ++
    (mkIncrementalSlide "SemiBin is a tool for others to use"
        [[ Html.div
            [HtmlAttr.style "float" "left"
            ,HtmlAttr.style "width" "300px"
            ,HtmlAttr.style "height" "300px"
            ,HtmlAttr.style "padding-left" "2em"
            ,HtmlAttr.style "padding-top" "2em"
            ]
            [C.chart
                [ CA.height 300
                , CA.width 300
                ]
                [ C.xLabels
                      [ CA.format (x2month .mo semiBinDownloadData)
                      ]
                , C.yLabels [ CA.withGrid ]
                , C.series .x
                    [ C.interpolated .downloads [  ] []
                    ]
                    semiBinDownloadData

                , C.labelAt CA.middle .min [ CA.moveDown 54 ]
                    [ S.text "Month (* March is extrapolated)" ]
                , C.labelAt CA.middle .max [ CA.moveUp 15]
                    [ S.text "How often is SemiBin being downloaded?" ]
                , C.labelAt CA.middle .max [ CA.fontSize 14 ]
                    [ S.text "Data from bioconda" ]
                ]]
        ]
        ,[ Html.div
            [HtmlAttr.style "float" "left"
            ,HtmlAttr.style "width" "300px"
            ,HtmlAttr.style "height" "300px"
            ,HtmlAttr.style "padding-left" "10em"
            ,HtmlAttr.style "padding-top" "2em"
            ]
            [C.chart
                [ CA.height 300
                , CA.width 300
                ]
                [ C.xLabels
                      [ CA.format (x2month .tool downloadsInMarch)
                      ]
                , C.yLabels [ CA.withGrid ]
                , C.bars []
                    [ C.bar .downloads [CA.color CA.blue]
                    ]
                    downloadsInMarch
                , C.labelAt CA.middle .max [ CA.moveUp 20]
                    [ S.text "March downloads (extrapolated)" ]
                , C.labelAt CA.middle .max [ CA.fontSize 14, CA.moveUp 5]
                    [ S.text "Data from bioconda" ]
                ]
            ,p "We develop several other tools"]
        ]
        ,[ Html.div
            [HtmlAttr.style "float" "left"
            ,HtmlAttr.style "width" "300px"
            ,HtmlAttr.style "height" "300px"
            ,HtmlAttr.style "margin-left" "6em"
            ,HtmlAttr.style "padding-left" "1em"
            ,HtmlAttr.style "padding-bottom" "2em"
            ,HtmlAttr.style "padding-bottom" "2em"
            ,HtmlAttr.style "border" "1px solid #333333"
            ]
            [mdToHtml """
### High quality tools

1. **Five-year support (from date of publication)**
2. **Standard, easy to install, packages**
3. **High-quality code with continuous integration**
4. **Complete documentation**
5. **Work well, fail well**
6. **Open source, open communication**

"""]
        ]])

x2month acc data x = case List.filter (\e -> e.x == x) data of
    (el::_) -> acc el
    [] -> ""

semiBinDownloadData =
    [{ mo = "2021-07", x = 0.0, downloads = 69.0 }
    ,{ mo = "2021-08", x = 1.0, downloads = 92.0 }
    ,{ mo = "2021-09", x = 2.0, downloads = 83.0 }
    ,{ mo = "2021-10", x = 3.0, downloads = 56.0 }
    ,{ mo = "2021-11", x = 4.0, downloads = 152.0 }
    ,{ mo = "2021-12", x = 5.0, downloads = 179.0 }
    ,{ mo = "2022-01", x = 6.0, downloads = 237.0 }
    ,{ mo = "2022-02", x = 7.0, downloads = 289.0 }
    ,{ mo = "2022-03", x = 8.0, downloads = 354.0 }
    ]

downloadsInMarch =
    [{ x = 1.0, tool = "SemiBin", downloads = 354.0 }
    ,{ x = 2.0, tool = "NGLess", downloads = 1116.0 }
    ,{ x = 3.0, tool = "Macrel", downloads =  704.0 }
    ]

ackList : String -> List String -> Html msg
ackList h ts =
    Html.div
        [HtmlAttr.attribute "style" "float: left; padding-left: 2em; "]
        [Html.h4 []
            [Html.text h]
        ,Html.ul []
            (List.map (\t -> Html.li [] [Html.text t]) ts)
        ]


summary =
    [mkSlide "Summary"
        [Html.ul []
            [Html.li []
                [ Html.text "The gut microbiome of dogs is similar to that of humans"]
            ,Html.li []
                [ Html.em [] [ Html.text "Global microbiome" ]
                , Html.text ": A lof of genes, but probably few meaningful differences!"]
            , Html.li []
                [ Html.text "Most genes are in a very small number of gene families."]
            , Html.li []
                [ Html.text "SemiBin incorporates background information for better MAGs"]
            , Html.li []
                [ Html.text "We are currently expanding to small proteins" ]
            , Html.li []
                [ Html.em [] [ Html.text "(Not discussed today): " ]
                , Html.text "We also have a project on antimicrobial resistance (but only preliminary results so far)"]
            ]]
    ,mkSlide "Acknowledgements"
            [ ackList "Global microbiome"
                  [ "Alvaro del Río (Madrid)"
                  , "Renato Alves (EMBL)"
                  , "Pernille Neve Meyers (DTU)"
                  , "Thomas Sebastian Schmidt (EMBL)"
                  , "Daniel Mende (EMBL; Amsterdam)"
                  , "Ivica Letunic (Biobyte)"
                  , "Falk Hildebrandt (EMBL; Norwich)"
                  , "Thea van Rossum (EMBL)"
                  , "Sofia K. Forslund (EMBL; Berlin)"
                  , "Supriya Khedkar (EMBL)"
                  , "Oleksandr Maistrenko (EMBL)"
                  , "Longhao Jia (Fudan)"
                  , "Pamela Ferretti (EMBL)"
                  , "Xingming Zhao (Fudan)"
                  , "Jaime Huerta-Cepas (EMBL; Madrid)"
                  , "Henrik Bjorn Nielsen (DTU)"
                  , "Peer Bork (EMBL)"
                  ]
              ,ackList "Macrel & smORF catalogue"
                [ "Célio Santos Dias-Junior (Fudan)"
                , "Yiqian Duan (Fudan)"
                , "Thomas Sebastian Schmidt (EMBL)"
                , "Shaojun Pan (Fudan)"
                , "Xingming Zhao (Fudan)"
                ]
              ,ackList "SemiBin"
                [ "Shaojun Pan (Fudan)"
                , "Chengkai Zhu (Fudan)"
                , "Xingming Zhao (Fudan)"
                ]
              ,Html.div
                [HtmlAttr.attribute "style" "float: left; padding-left: 2em; "]
                  [Html.h4 [] [Html.text "Funding"]
                  ,Html.img [HtmlAttr.src "/Media/funding/Idrc-logo-full-name-wordmark.png", HtmlAttr.style "height" "92px"] []
                  ,Html.br [] []
                  ,Html.img [HtmlAttr.src "/Media/funding/jpiamr.jpeg", HtmlAttr.style "height" "92px"] []
                  ,Html.br [] []
                  ,Html.img [HtmlAttr.src "/Media/funding/nsfc.png", HtmlAttr.style "height" "92px"] []
              ]]
    ,{ content =
            Html.div [HtmlAttr.class "slide"]
                [Html.h2 [
                    HtmlAttr.style "padding-top" "50vh"
                    ,HtmlAttr.style "padding-left" "50%"
                    ,HtmlAttr.style "font-size" "64px"] [Html.text "Thank you"]]
     , slideType = Follower }
            ]

historical =
    (mkIncrementalSlide "The gut microbiome of dogs is similar to humans"
        [[Html.div
            [HtmlAttr.style "float" "left"
            ,HtmlAttr.style "padding-left" "2em"
            ,HtmlAttr.style "padding-right" "2em"
            ]
            [Html.img
                [HtmlAttr.src "/Media/2018_Dogs/dog-catalog.png"
                ,HtmlAttr.style "height" "520px"
                ] []]]
        ,[Html.div
            [HtmlAttr.style "float" "left"]
            [Html.img
                [HtmlAttr.src "/Media/2018_Dogs/Fig1f.svg"
                ,HtmlAttr.style "height" "520px"
                ] []]]]) ++
    [mkSlide "The gut microbiome of dogs is similar to humans"
        [Html.div
            [HtmlAttr.style "margin" "0px 12em"]
            [Html.img
                    [HtmlAttr.src "/Media/2018_Dogs/Waiting for the Vet Rockwell Print.jpg"
                    ,HtmlAttr.style "height" "560px"
                    ] []
            ]
        ,mdToHtml "[(Coelho et al., Microbiome, 2018)](https://microbiomejournal.biomedcentral.com/articles/10.1186/s40168-018-0450-3)"]
        ] ++
    mkIncrementalSlide "The microbiome of obsese dogs is less stable"
        [[Html.div
            [HtmlAttr.style "float" "left"]
            [Html.img
                [HtmlAttr.src "/Media/2018_Dogs/Fig2a.svg"
                ,HtmlAttr.style "margin-top" "-20px"
                ,HtmlAttr.style "height" "380px"]
            []]]
        ,[Html.div
            [HtmlAttr.style "float" "left"]
            [Html.img
                [HtmlAttr.src "/Media/2018_Dogs/Fig2c.svg"
                ,HtmlAttr.style "margin-top" "-20px"
                ,HtmlAttr.style "height" "380px"]
            [] ]]
        ,[Html.div
            [HtmlAttr.style "float" "left"]
            [Html.img
                [HtmlAttr.src "/Media/2018_Dogs/Fig2d.svg"
                ,HtmlAttr.style "height" "360px"]
                []]]
        ]
