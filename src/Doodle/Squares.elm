module Doodle.Squares exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Dom exposing (Viewport, getViewport)
import Browser.Events exposing (onAnimationFrame)
import Color
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Random
import Random.Extra as RandomExtra
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
    | NewRandomSquare
    | RandomSquare Square


generateRandomSquares : Int -> List (Cmd Msg) -> List (Cmd Msg)
generateRandomSquares n list =
    case n of
        0 ->
            list

        _ ->
            generateRandomSquares (n - 1) [ Task.succeed NewRandomSquare |> Task.perform identity ] ++ list


init : Session.Model -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , viewport = Nothing
      , squares = []
      }
    , Cmd.batch <|
        Task.perform GotViewport getViewport
            :: generateRandomSquares 200 []
    )


randomSquare : Random.Generator Square
randomSquare =
    Random.map Square randomPosition
        |> RandomExtra.andMap randomPosition
        |> RandomExtra.andMap randomDelta
        |> RandomExtra.andMap randomDelta
        |> RandomExtra.andMap randomColor


randomPosition : Random.Generator Int
randomPosition =
    let
        minPos =
            0

        maxPos =
            800
    in
    Random.int minPos maxPos


randomDelta : Random.Generator Int
randomDelta =
    let
        minDelta =
            1

        maxDelta =
            5
    in
    Random.int minDelta maxDelta


randomRGBValue : Random.Generator Float
randomRGBValue =
    Random.float 0 255


randomColor : Random.Generator Color
randomColor =
    Random.map3 Color randomRGBValue randomRGBValue randomRGBValue


newRandomSquare : Cmd Msg
newRandomSquare =
    Random.generate RandomSquare randomSquare



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotViewport viewport ->
            ( { model | viewport = Just viewport }, Cmd.none )

        NewRandomSquare ->
            ( model, newRandomSquare )

        RandomSquare { xPos, yPos, xDelta, yDelta, color } ->
            let
                newSquare =
                    { xPos = xPos
                    , yPos = yPos
                    , xDelta = xDelta
                    , yDelta = yDelta
                    , color = color
                    }
            in
            ( { model | squares = newSquare :: model.squares }, Cmd.none )

        Tick _ ->
            case model.viewport of
                Just viewport ->
                    ( { model | squares = tickSquares viewport model.squares }, Cmd.none )

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
            nextValue color.green 0.002

        nextBlue =
            nextValue color.blue 0.003
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
        , width "20"
        , height "20"
        , rx "2"
        , ry "2"
        ]
        []
