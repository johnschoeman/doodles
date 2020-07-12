module Doodle.Squares exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Dom exposing (Viewport, getViewport)
import Browser.Events exposing (onAnimationFrame)
import Color
import Html exposing (Html, div, text)
import Html.Attributes as Attr exposing (class, style, type_, value)
import Session exposing (WithSession)
import Svg exposing (rect, svg)
import Svg.Attributes exposing (fill, height, rx, ry, viewBox, width, x, y)
import Task
import Time


type alias Square =
    { xPos : Int
    , yPos : Int
    , xDelta : Int
    , yDelta : Int
    , color : Color
    }


type alias Color =
    { red : Float
    , green : Float
    , blue : Float
    }


type alias Model =
    WithSession
        { viewport : Maybe Viewport
        , squares : List Square
        }


type Msg
    = GotViewport Viewport
    | Tick Time.Posix


red : Color
red =
    { red = 100
    , green = 0
    , blue = 0
    }


green : Color
green =
    { red = 0
    , green = 100
    , blue = 0
    }


blue : Color
blue =
    { red = 0
    , green = 0
    , blue = 100
    }


init : Session.Model -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , viewport = Nothing
      , squares =
            [ { xPos = 100
              , yPos = 200
              , xDelta = 1
              , yDelta = 1
              , color = red
              }
            , { xPos = 200
              , yPos = 100
              , xDelta = 2
              , yDelta = 2
              , color = green
              }
            ]
      }
    , Task.perform GotViewport getViewport
    )



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotViewport viewport ->
            ( { model | viewport = Just viewport }, Cmd.none )

        Tick now ->
            let
                time =
                    Debug.log <| Debug.toString now

                oldSquares =
                    model.squares
            in
            case model.viewport of
                Just viewport ->
                    ( { model | squares = tickSquares viewport oldSquares }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


tickSquares : Viewport -> List Square -> List Square
tickSquares viewport squares =
    List.map (tickSquare viewport) squares


tickSquare : Viewport -> Square -> Square
tickSquare viewport { xPos, yPos, xDelta, yDelta, color } =
    let
        { width, height } =
            viewport.viewport

        newXPos =
            modBy (ceiling width) (xPos + xDelta)

        newYPos =
            modBy (ceiling height) (yPos + yDelta)
    in
    { xPos = newXPos
    , yPos = newYPos
    , xDelta = xDelta
    , yDelta = yDelta
    , color = nextColor color
    }


nextColor : Color -> Color
nextColor color =
    let
        nextValue c rate =
            toFloat <| modBy 255 (ceiling (c + rate))

        nextRed =
            nextValue color.red 0.001

        nextGreen =
            nextValue color.green 0.003

        nextBlue =
            nextValue color.blue 0.002
    in
    { red = nextRed
    , green = nextGreen
    , blue = nextBlue
    }



---- SUBSCRIPTIONS ----


subscriptions : Sub Msg
subscriptions =
    onAnimationFrame Tick



---- VIEW ----


view : Model -> Html Msg
view model =
    case model.viewport of
        Just viewport ->
            div []
                [ art viewport model
                ]

        Nothing ->
            div [] [ text "loading..." ]


art : Viewport -> Model -> Html Msg
art viewport model =
    let
        { width, height } =
            viewport.viewport

        heightString =
            String.fromInt <| ceiling height

        widthString =
            String.fromInt <| ceiling width
    in
    div [ class "border bg-gray-100" ]
        [ svg [ viewBox <| String.join " " [ "0 0", widthString, heightString ] ]
            (List.map squareSvg model.squares)
        ]


colorToRGB : Color -> String
colorToRGB color =
    Color.fromRGB ( color.red, color.green, color.blue )
        |> Color.toRGBString


squareSvg : Square -> Html msg
squareSvg { xPos, yPos, color } =
    rect
        [ x <| String.fromInt xPos
        , y <| String.fromInt yPos
        , fill <| colorToRGB color
        , width "100"
        , height "100"
        , rx "2"
        , ry "2"
        ]
        []
