module Collage.Layout
    exposing
        ( Direction(..)
        , envelope
        , spacer
        , empty
        , above
        , beside
        , horizontal
        , vertical
        , layer
        , north
        , east
        , south
        , west
        , center
        )

import Tuple exposing (first, second)
import Maybe.Extra exposing ((?))
import Collage exposing (..)


-- Directions ------------------------------------------------------------------


{-| Represents a `flow` direction for a list of elements.
-}
type Direction
    = Up
    | Down
    | Left
    | Right



-- Envelopes -------------------------------------------------------------------


envelope : Direction -> Form msg -> Float
envelope dir form =
    let
        env =
            basicEnvelope dir form.basic

        ( tx, ty ) =
            form.origin
    in
        --TODO: rotation
        form.scale
            * case dir of
                Up ->
                    max 0 (env + ty)

                Down ->
                    max 0 (env - ty)

                Right ->
                    max 0 (env + tx)

                Left ->
                    max 0 (env - tx)


basicEnvelope : Direction -> BasicForm msg -> Float
basicEnvelope dir basic =
    case basic of
        Shape _ (Polygon ps) ->
            pathEnvelope dir ps

        Shape style (Ellipse rx ry) ->
            boxEnvelope dir (2 * rx) (2 * ry) style.line.thickness

        Path _ (Polyline ps) ->
            pathEnvelope dir ps

        Image _ w h ->
            boxEnvelope dir w h 0

        Group forms ->
            (List.maximum <| List.map (envelope dir) forms) ? 0

        --FIXME: calculate envelope for Element
        Element _ ->
            0


pathEnvelope : Direction -> List Point -> Float
pathEnvelope dir ps =
    let
        xs =
            List.map first ps

        ys =
            List.map second ps
    in
        case dir of
            Up ->
                List.maximum ys ? 0

            Down ->
                -(List.minimum ys ? 0)

            Right ->
                List.maximum xs ? 0

            Left ->
                -(List.minimum xs ? 0)


boxEnvelope : Direction -> Float -> Float -> Float -> Float
boxEnvelope dir width height thickness =
    thickness
        + case dir of
            Up ->
                height / 2

            Down ->
                height / 2

            Right ->
                width / 2

            Left ->
                width / 2



-- Layouts ---------------------------------------------------------------------


spacer : Float -> Float -> Form msg
spacer w h =
    rectangle w h |> styled transparent invisible


empty : Form msg
empty =
    spacer 0 0


{-| Given two diagrams a and b, place b to the right of a, such that their origins
are on a horizontal line and their envelopes touch. The origin of the new diagram
is the center of top and bot.FIXME

    top
        |> above bot

-}
above : Form msg -> Form msg -> Form msg
above bot top =
    let
        ty =
            (envelope Down top) + (envelope Up bot)
    in
        layer [ top, translate ( 0, -ty ) bot ]


{-| Given two diagrams a and b, place b to the right of a, such that their origins
are on a horizontal line and their envelopes touch. The origin of the new diagram
is the origin of a.

    left
        |> beside right

-}
beside : Form msg -> Form msg -> Form msg
beside right left =
    let
        tx =
            (envelope Right left) + (envelope Left right)
    in
        layer [ right, translate ( tx, 0 ) left ]


{-| Have a list of elements flow in a particular direction.
The `Direction` starts from the first element in the list.

flow Right [a,b,c]

       +---+---+---+
       | a | b | c |
       +---+---+---+

-}
vertical : List (Form msg) -> Form msg
vertical =
    List.foldr (flip above) empty


horizontal : List (Form msg) -> Form msg
horizontal =
    List.foldr (flip beside) empty


layer : List (Form msg) -> Form msg
layer =
    -- LOL
    Collage.group



-- Anchors ---------------------------------------------------------------------


{-| Translate a diagram such that the origin is on the top edge of the bounding box
-}
north : Form msg -> Form msg
north form =
    translate ( 0, -(envelope Up form) ) form


{-| Translate a diagram such that the origin is on the right edge of the bounding box
-}
east : Form msg -> Form msg
east form =
    translate ( -(envelope Right form), 0 ) form


{-| Translate a diagram such that the origin is on the bottom edge of the bounding box
-}
south : Form msg -> Form msg
south form =
    translate ( 0, envelope Down form ) form


{-| Translate a diagram such that the origin is on the left edge of the bounding box
-}
west : Form msg -> Form msg
west form =
    translate ( envelope Left form, 0 ) form


{-| Translate a diagram such that the envelope in all directions is equal
-}
center : Form msg -> Form msg
center form =
    let
        left =
            envelope Left form

        right =
            envelope Right form

        tx =
            (right - left) / 2

        up =
            envelope Up form

        down =
            envelope Down form

        ty =
            (down - up) / 2
    in
        translate ( -tx, ty ) form
