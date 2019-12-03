module Main exposing (main)

import Array
import BoundingBox2d
import Geometry.Svg
import List.Extra as List
import Point2d
import Random
import Result
import Svg exposing (..)
import Svg.Attributes exposing (..)
import VoronoiDiagram2d


main =
    let
        cnvs =
            canvas 800 600

        pointCoordsx =
            List.range 0 19
                |> List.map (\n -> n * 40 + 20)

        pointCoordsy =
            List.range 0 14
                |> List.map (\n -> n * 40 + 20)

        -- tesselation
        -- ( perturbationsX, newSeed1 ) =
        --     Random.list (List.length gridCoordsx) (Random.int -5 5)
        --         |> (\l -> Random.step l (Random.initialSeed 2))
        -- ( perturbationsY, _ ) =
        --     Random.list (List.length gridCoordsy) (Random.int -5 5)
        --         |> (\l -> Random.step l newSeed1)
        -- pointCoordsx =
        --     List.map2 (+) gridCoordsx perturbationsX
        -- pointCoordsy =
        --     List.map2 (+) gridCoordsx perturbationsY
        pointCoordsPure =
            List.lift2 Tuple.pair pointCoordsx pointCoordsy

        ( randomCoordList, _ ) =
            Random.pair (Random.int -5 5) (Random.int -5 5)
                |> Random.list (List.length pointCoordsPure)
                |> (\l -> Random.step l (Random.initialSeed 2))

        pointCoords =
            List.map2 (\( cx, cy ) ( p1, p2 ) -> ( cx + p1, cy + p2 ))
                pointCoordsPure
                randomCoordList

        points =
            pointCoords
                |> List.map (\( xc, yc ) -> ( toFloat xc, toFloat yc ))
                |> List.map (\( xc, yc ) -> Point2d.unitless xc yc)
                |> Array.fromList

        markers =
            Array.map Point2d.toUnitless points
                |> Array.map (\p -> ( round p.x, round p.y ))
                |> Array.map marker
                |> Array.toList

        voronoi =
            VoronoiDiagram2d.fromPoints points
                |> Result.withDefault VoronoiDiagram2d.empty

        polygons =
            VoronoiDiagram2d.polygons
                (BoundingBox2d.from (Point2d.unitless 0 0) (Point2d.unitless 800 600))
                voronoi

        svgPolygons =
            List.map
                (\( _, p ) -> Geometry.Svg.polygon2d [ stroke "#555555", fillOpacity "0" ] p)
                polygons
    in
    cnvs
        [ g [] markers
        , g [] svgPolygons
        ]



-- SVG HELPERS


marker : ( Int, Int ) -> Svg msg
marker ( xc, yc ) =
    circle
        [ cx <| String.fromInt xc
        , cy <| String.fromInt yc
        , r "2"
        , stroke "#aaaaaa"
        , fillOpacity "0"
        ]
        []



-- CANVAS HELPERS


canvas : Int -> Int -> List (Svg msg) -> Svg msg
canvas w h children =
    let
        hStr =
            String.fromInt h

        wStr =
            String.fromInt w

        tileSize =
            10

        xnumtiles =
            w // tileSize

        ynumtiles =
            h // tileSize

        tiles =
            List.lift2 (tile tileSize)
                (List.range 0 <| xnumtiles - 1)
                (List.range 0 <| ynumtiles - 1)

        border =
            rect
                [ x "0"
                , y "0"
                , width wStr
                , height hStr
                , stroke "red"
                , strokeWidth "2"
                , fillOpacity "0"
                ]
                []
    in
    svg
        [ width wStr
        , height hStr
        , viewBox <| "0 0 " ++ wStr ++ " " ++ hStr
        ]
        [ g [] tiles
        , border
        , g [] children
        ]


tile : Int -> Int -> Int -> Svg msg
tile size xc yc =
    let
        col =
            if modBy 2 (xc + yc) == 0 then
                "#eeeeee"

            else
                "#ffffff"
    in
    rect
        [ x (String.fromInt (xc * size))
        , y (String.fromInt (yc * size))
        , width (String.fromInt size)
        , height (String.fromInt size)
        , fill col
        ]
        []
