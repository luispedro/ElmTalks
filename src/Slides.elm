module Slides exposing (Slide, SlideShow, slides)

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

type alias Slide msg = Html msg
type alias SlideShow msg = List (Slide msg)


mkSlide : String -> List (Html msg) -> Slide msg
mkSlide title body =
    Html.div
        [HtmlAttr.class "slide"]
        (Html.h2 [] [Html.text title] :: body)


mkIncrementalSlide : String -> List (List (Html msg)) -> List (Slide msg)
mkIncrementalSlide title parts =
    List.map (\ix ->
        mkSlide title (List.concat (List.take ix parts)))
        <| List.range 0 (List.length parts)

markdownOptions =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }
mdToHtml = Markdown.toHtmlWith markdownOptions []

img80 src =
    Html.img
        [HtmlAttr.src src
        ,HtmlAttr.style "width" "80%"]
        []

p t = Html.p [] [Html.text t]




------------------------------------------





slides = List.concat
    [gmgcv1slides
    ,newFamiliesSlides
    ,semiBin
    ,gmgcv2
    ,ampSlides
    ]


gmgcv1slides =
    [
        mkSlide "The global microbiome"
            [Html.img [HtmlAttr.src "/Media/GMGC/Fig1a-layered.svg"
                      ,HtmlAttr.style "height" "800px"]
                      []
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
- <li>Marine environment (130 samples, <a href="" class="citation">Sunagawa, Coelho, Chaffon et al., 2015</a>)
- Built-environment (1295 samples, <a href="" class="citation">MetaSUB consortium</a>)
- ...

Reworked data from scratch _using a consistent methodology_
"""]
        ,mkSlide "We also have 46,655 MAGs, but they miss many genes"
            [mdToHtml """
<img src="/Media/GMGC/Bork_EDfig4.png" style="height: 800px" />

- This is including the 75,674 <em>medium-quality</em> bins (for a total of 122k high- or medium-quality bins)
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
            [img80 "/Media/GMGC/SupplFigure9-all-habitats-mobility.svg"
            ,p "Environmental samples are a mixture of sub-habitats"
            ]
        ,mkSlide "Most of these genes belong to a small number of gene families"
            [img80 "/Media/GMGC/submission.2020.04/Figure2-gf-sizes.svg"
            ]

        ,mkSlide "Most genes are rare"
            [img80 "/Media/GMGC/submission.2020.04/Figure5-rare.svg"
            ,mdToHtml "This is what is predicted by _>models of (nearly-)neutral evolution_"]

        ,mkSlide "Most genes and rare ones, in particular, are not under selection"
            [
            Html.div [HtmlAttr.style "float" "left"]
                [Html.img
                    [HtmlAttr.src "/Media/GMGC/submission.2020.04/Figure6-selection.svg"
                    ,HtmlAttr.style "height" "560px"]
                    []]
            ,
            Html.div [HtmlAttr.style "float" "left"]
                [p "At different levels"
                ,Html.ul []
                    [Html.li [] [Html.text " Low levels of selection"]
                    ,Html.li [] [Html.text " Increased selection for more prevalent genes"]]
                    ]
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

    ,mkIncrementalSlide "The future of GMGC II: Smaller peptides"
        [

            [mdToHtml """In the work I showed you before, we ignored any
            sequences that were _too small_, namely those under 32 amino-acids. We are currently looking into those!"""]
            ,[mdToHtml """
**First target**: antimicrobial peptides (AMPs), which are
1. short peptides (≤ 100 amino acids)
2. antimicrobial

AMPs are already widely used in industrial applications (less so clinically)
"""]
            ,[mdToHtml """
### Small genes are not just like other genes, but smaller

- Hard to predict genes
- Hard to assign function by homology
- No modules/families &c
"""
            ,personImage "Yiqian Duan" "/Media/BigDataBiology/people/YiqianDuan.jpg"
            ,personImage "Célio Dias Santos-Júnior"
                    "/Media/BigDataBiology/people/CelioDiasSantosJunior.jpg"
            ]

        ]
    ]
ampSlides = List.concat
    [[mkSlide "Macrel"
        [img80 "/Media/macrel/2020-04/Fig1_touched.svg"
        ,Html.br [] []
        ,Html.p []
            [Html.a [HtmlAttr.href "https://peerj.com/articles/10555/"]
            [Html.text "(Dias Santos-Junior, et al., 2020)"]
            ]
        ,Html.p []
            [Html.a [HtmlAttr.href "https://big-data-biology.org/software/macrel"]
            [Html.text "https://big-data-biology.org/software/macrel"]
            ]]
    ,mkSlide "Evaluation against standard benchmarks"
        [img80 "/Media/macrel/Table_performance.png"
        ]]

    ,ampCatalogBuild
    ,[mkSlide "The AMPSphere: almost one million AMP candidates"
        [img80 "/Media/AMPsphere/Fig1.png"]
    ]]

ampCatalogBuild : List (Slide msg)
ampCatalogBuild =
    List.map (\ix ->
        mkSlide "Building a catalog of AMPs"
        [img80 (String.concat
                    ["/Media/AMPsphere/creation/frame"
                    ,String.fromInt ix
                    ,".png"])
        ,p "We are applying the same general approach as GMGC: process all (meta)genomes with a consistent methodology"
        ]) (List.range 0 9)


semiBin : List (Slide msg)
semiBin =
    [mkSlide "SemiBin: using deep learning outperforms state-of-the-art"
        [img80 "/Media/SemiBin/Fig3b.svg"
        ,personImage "Shaojun Pan" "/Media/BigDataBiology/people/ShaojunPan.jpg"
        ]
    ,mkSlide "SemiBin works across many habitats"
        [img80 "/Media/SemiBin/Fig5.svg"
        ,mdToHtml """
_Similar_ environments behave similarly

[(Pan el al., Nat Comms, <i>Accepted in principle</i>)](https://www.biorxiv.org/content/10.1101/2021.08.16.456517v1.full)
"""]]
