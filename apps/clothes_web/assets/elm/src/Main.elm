module Main exposing (main)

import Browser
import Browser.Events as BE
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import FontAwesome.Duotone as Duotone
import FontAwesome.Icon as Icon exposing (Icon)
import FontAwesome.Styles as Icon
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Svg
import Url
import Url.Builder as Builder



-- MAIN


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Api =
    String


type alias ClothingItem =
    { id : Int
    , color : String
    , name : String
    }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , api : Api
    , user : String
    , clothes : List ClothingItem
    , colorInput : String
    , nameInput : String
    , showTooltip : Bool
    , mousePosition : ( Float, Float )
    }


type FormInput
    = Color
    | Name


init : Decode.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsJson url key =
    let
        api =
            case Decode.decodeValue apiDecoder flagsJson of
                Ok decodedApi ->
                    decodedApi

                Err error ->
                    Debug.log (Decode.errorToString error) ""
    in
    ( Model key
        url
        api
        "Raul"
        -- clothing items
        []
        -- colorInput
        ""
        -- nameInput
        ""
        -- showTooltip
        False
        -- mousePosition
        ( 0.0, 0.0 )
    , requestClothes api "raul"
    )



-- HTTP COMMANDS


requestClothes : String -> String -> Cmd Msg
requestClothes url userId =
    Http.get
        { url = Builder.relative [ url ] [ Builder.string "user" userId ]
        , expect = Http.expectJson ClothesLoaded clothingItemsDecoder
        }


addItem : String -> String -> { color : String, name : String } -> Cmd Msg
addItem url userId item =
    Http.post
        { url = Builder.relative [ url ] [ Builder.string "user" userId ]
        , body = Http.jsonBody (itemEncoder item)
        , expect = Http.expectJson ItemAdded (itemDecoder item)
        }


deleteItem : String -> String -> Int -> Cmd Msg
deleteItem url userId id =
    Http.request
        { method = "DELETE"
        , headers = []
        , url =
            Builder.relative
                [ url
                , String.fromInt id
                ]
                [ Builder.string "user" userId ]
        , body = Http.emptyBody
        , expect = Http.expectWhatever (ItemDeleted id)
        , timeout = Nothing
        , tracker = Nothing
        }



-- DECODERS


apiDecoder : Decode.Decoder Api
apiDecoder =
    Decode.at [ "api", "items" ] Decode.string


clothingItemsDecoder : Decode.Decoder (List ClothingItem)
clothingItemsDecoder =
    Decode.field "data" <|
        Decode.list <|
            Decode.map3 ClothingItem
                (Decode.field "id" Decode.int)
                (Decode.field "color" Decode.string)
                (Decode.field "name" Decode.string)


itemDecoder : { color : String, name : String } -> Decode.Decoder ClothingItem
itemDecoder item =
    Decode.field "data" <|
        Decode.map3 ClothingItem
            (Decode.field "id" Decode.int)
            (Decode.succeed item.color)
            (Decode.succeed item.name)


itemEncoder : { color : String, name : String } -> Encode.Value
itemEncoder item =
    Encode.object
        [ ( "data"
          , Encode.object
                [ ( "color", Encode.string item.color )
                , ( "name", Encode.string item.name )
                ]
          )
        ]



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ClothesLoaded (Result Http.Error (List ClothingItem))
    | TypedInput FormInput String
    | MouseMoved ( Float, Float )
    | EnteredTooltip
    | LeftTooltip
    | AddPressed
    | DeletePressed Int
    | ItemAdded (Result Http.Error ClothingItem)
    | ItemDeleted Int (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

        ClothesLoaded result ->
            case result of
                Ok items ->
                    ( { model | clothes = items }, Cmd.none )

                Err error ->
                    ( model, Cmd.none )

        TypedInput inputType inputValue ->
            case inputType of
                Color ->
                    ( { model | colorInput = inputValue }, Cmd.none )

                Name ->
                    ( { model | nameInput = inputValue }, Cmd.none )

        MouseMoved pos ->
            ( { model | mousePosition = pos }, Cmd.none )

        EnteredTooltip ->
            ( { model | showTooltip = True }, Cmd.none )

        LeftTooltip ->
            ( { model | showTooltip = False }, Cmd.none )

        AddPressed ->
            ( { model | colorInput = "", nameInput = "" }
            , addItem model.api
                "raul"
                { color = model.colorInput
                , name = model.nameInput
                }
            )

        DeletePressed id ->
            ( model, deleteItem model.api "raul" id )

        ItemAdded result ->
            case result of
                Ok item ->
                    ( { model | clothes = item :: model.clothes }, Cmd.none )

                Err error ->
                    ( model, Cmd.none )

        ItemDeleted id result ->
            case result of
                Ok () ->
                    ( { model
                        | clothes =
                            List.filter
                                (\item -> item.id /= id)
                                model.clothes
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.showTooltip then
        BE.onMouseMove (Decode.map MouseMoved decodePosition)

    else
        Sub.none


decodePosition : Decode.Decoder ( Float, Float )
decodePosition =
    Decode.map2 Tuple.pair
        (decodeCoordinate "pageX")
        (decodeCoordinate "pageY")


decodeCoordinate : String -> Decode.Decoder Float
decodeCoordinate field =
    Decode.field field Decode.float



-- VIEW


edges =
    { top = 0, right = 0, bottom = 0, left = 0 }


colors =
    { royalBlue = rgb 0.25 0.41 0.88
    , warning = rgb 0.88 0.05 0.05
    , lightRed = rgb 0.88 0.35 0.35
    , offWhite = rgb 0.97 0.97 0.97
    , black = rgb 0.1 0.1 0.1
    }


view : Model -> Browser.Document Msg
view model =
    let
        subtitle =
            case model.user of
                "" ->
                    "Nobody's clothes"

                _ ->
                    model.user ++ "'s clothes"
    in
    Browser.Document "Wardrobe"
        [ Icon.css
        , layout
            [ inFront
                (el
                    [ moveRight (Tuple.first model.mousePosition + 20.0)
                    , moveDown (Tuple.second model.mousePosition - 5.0)
                    ]
                    (viewTooltip model.showTooltip)
                )
            ]
          <|
            column []
                [ text "My Clothes"
                , viewForm model.colorInput model.nameInput
                , text subtitle
                , column [ spacing 3 ] (List.map viewItem model.clothes)
                ]
        ]


viewForm : String -> String -> Element Msg
viewForm colorInput nameInput =
    let
        viewPlaceholder placeholder =
            Just (Input.placeholder [] (text placeholder))
    in
    row []
        [ Input.text []
            { onChange = TypedInput Color
            , text = colorInput
            , placeholder = viewPlaceholder "enter a color"
            , label = Input.labelAbove [] (text "color")
            }
        , Input.text []
            { onChange = TypedInput Name
            , text = nameInput
            , placeholder = viewPlaceholder "enter a name"
            , label = Input.labelAbove [] (text "name")
            }
        , Input.button [ Border.width 1, Border.color colors.black ]
            { onPress = Just AddPressed
            , label = text "Add Item"
            }
        ]


viewItem : ClothingItem -> Element Msg
viewItem { id, color, name } =
    column [ width fill ]
        [ row [ width fill, spacing 5 ]
            [ el [ width <| fillPortion 20 ]
                (text
                    (String.join " "
                        [ String.fromInt id ++ ":"
                        , color
                        , name
                        ]
                    )
                )
            , el
                [ width <| fillPortion 1
                , pointer
                , mouseOver [ Font.color colors.warning ]
                , Events.onClick <| DeletePressed id
                , Events.onMouseEnter EnteredTooltip
                , Events.onMouseLeave LeftTooltip
                ]
                (viewIcon Duotone.trashAlt [])
            ]
        ]


viewIcon : Icon -> List (Svg.Attribute msg) -> Element msg
viewIcon icon styles =
    html (icon |> Icon.present |> Icon.styled styles |> Icon.view)


viewTooltip : Bool -> Element msg
viewTooltip show =
    if show then
        el
            [ Font.size 12
            , Font.color colors.offWhite
            , Background.color colors.lightRed

            --Border.color colors.black
            --, Border.width 1
            , paddingEach { edges | top = 5, bottom = 4, left = 4, right = 4 }
            ]
            (text "Delete item")

    else
        none



--view model =
--    { title = "URL Interceptor"
--    , body =
--        [ text "The current URL is: "
--        , b [] [ text (Url.toString model.url) ]
--        , ul []
--            [ viewLink "/home"
--            , viewLink "/profile"
--            , viewLink "/reviews/the-century-of-the-self"
--            , viewLink "/reviews/public-opinion"
--            , viewLink "/reviews/shah-of-shahs"
--            ]
--        ]
--    }
--viewLink : String -> Html msg
--viewLink path =
--    li [] [ a [ href path ] [ text path ] ]
