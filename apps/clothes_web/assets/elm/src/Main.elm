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
    , state : ItemState
    }


type ItemState
    = ModeEdit
    | ModeView


swapState : Int -> ClothingItem -> ClothingItem
swapState id item =
    if id == item.id then
        let
            newState =
                case item.state of
                    ModeEdit ->
                        ModeView

                    ModeView ->
                        ModeEdit
        in
        { item | state = newState }

    else
        item


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , api : Api
    , user : String
    , clothes : List ClothingItem
    , colorInput : String
    , nameInput : String
    , showTooltip : TooltipState
    , mousePosition : ( Float, Float )
    }


type TooltipState
    = Off
    | On Tooltip


type Tooltip
    = Delete
    | Edit


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
        Off
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
            Decode.map4 ClothingItem
                (Decode.field "id" Decode.int)
                (Decode.field "color" Decode.string)
                (Decode.field "name" Decode.string)
                (Decode.succeed ModeView)


itemDecoder : { color : String, name : String } -> Decode.Decoder ClothingItem
itemDecoder item =
    Decode.field "data" <|
        Decode.map4 ClothingItem
            (Decode.field "id" Decode.int)
            (Decode.succeed item.color)
            (Decode.succeed item.name)
            (Decode.succeed ModeView)


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
    | EnteredTooltip Tooltip
    | LeftTooltip
    | AddPressed
    | DeletePressed Int
    | EditPressed Int
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

        EnteredTooltip tooltip ->
            ( { model | showTooltip = On tooltip }, Cmd.none )

        LeftTooltip ->
            ( { model | showTooltip = Off }, Cmd.none )

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

        EditPressed id ->
            ( { model | clothes = List.map (swapState id) model.clothes }
            , Cmd.none
            )

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
    case model.showTooltip of
        Off ->
            Sub.none

        On _ ->
            BE.onMouseMove (Decode.map MouseMoved decodePosition)


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
    , bananaMania = rgb 0.98 0.906 0.71
    , cadmiumGreen = rgb 0 0.42 0.235
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
            column [ width fill ]
                [ text "My Clothes"
                , viewForm model.colorInput model.nameInput
                , text subtitle
                , viewItems model.clothes
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


viewItems : List ClothingItem -> Element Msg
viewItems items =
    --column [ spacing 3, width fill ] (List.map viewItem items)
    table []
        { data = items
        , columns =
            [ { header = text "Color"
              , width = fillPortion 2
              , view = \{ color, state } -> viewField (viewProperty color state)
              }
            , { header = text "Name"
              , width = fillPortion 3
              , view = \{ name, state } -> viewField (viewProperty name state)
              }
            , { header = none
              , width = fillPortion 2
              , view = \{ id } -> viewField (viewEditButton id)
              }
            , { header = none
              , width = fillPortion 1
              , view = \{ id } -> viewField (viewDeleteButton id)
              }
            ]
        }


viewField : Element Msg -> Element Msg
viewField child =
    column
        [ Border.widthEach { edges | top = 1 }
        , paddingEach { edges | top = 3, left = 3, bottom = 3 }
        , height fill
        ]
        [ child ]


viewProperty : String -> ItemState -> Element Msg
viewProperty value state =
    case state of
        ModeView ->
            el
                [ height (px 46)
                , paddingEach { edges | top = 13, left = 13 }
                ]
                (text value)

        ModeEdit ->
            Input.text [ height (px 46) ]
                { onChange = TypedInput Color
                , text = value
                , placeholder = Nothing
                , label = Input.labelHidden value
                }


viewEditButton : Int -> Element Msg
viewEditButton id =
    el
        [ mouseOver [ Font.color colors.cadmiumGreen ]
        , Events.onClick <| EditPressed id
        , Events.onMouseEnter (EnteredTooltip Edit)
        , Events.onMouseLeave LeftTooltip
        , centerY
        , centerX
        ]
        (viewIcon Duotone.edit [])


viewDeleteButton : Int -> Element Msg
viewDeleteButton id =
    el
        [ pointer
        , mouseOver [ Font.color colors.warning ]
        , Events.onClick <| DeletePressed id
        , Events.onMouseEnter (EnteredTooltip Delete)
        , Events.onMouseLeave LeftTooltip
        , centerY
        ]
        (viewIcon Duotone.trashAlt [])


viewItem : ClothingItem -> Element Msg
viewItem { id, color, name, state } =
    let
        itemDetails =
            case state of
                ModeView ->
                    el [ width fill ]
                        (text
                            (String.join " "
                                [ color
                                , name
                                ]
                            )
                        )

                ModeEdit ->
                    row [ width fill ]
                        [ Input.text []
                            { onChange = TypedInput Color
                            , text = color
                            , placeholder = Nothing
                            , label = Input.labelHidden "color"
                            }
                        , Input.text []
                            { onChange = TypedInput Name
                            , text = name
                            , placeholder = Nothing
                            , label = Input.labelHidden "name"
                            }
                        , Input.button [ Border.width 1, Border.color colors.black ]
                            { onPress = Nothing
                            , label = text "Save"
                            }
                        , Input.button [ Border.width 1, Border.color colors.black ]
                            { onPress = Nothing
                            , label = text "Cancel"
                            }
                        ]
    in
    column [ width fill ]
        [ row [ width fill, spacing 5 ]
            [ itemDetails
            , el
                [ mouseOver [ Font.color colors.cadmiumGreen ]
                , Events.onClick <| EditPressed id
                , Events.onMouseEnter (EnteredTooltip Edit)
                , Events.onMouseLeave LeftTooltip
                ]
                (viewIcon Duotone.edit [])
            , row []
                [ el
                    [ pointer
                    , mouseOver [ Font.color colors.warning ]
                    , Events.onClick <| DeletePressed id
                    , Events.onMouseEnter (EnteredTooltip Delete)
                    , Events.onMouseLeave LeftTooltip
                    ]
                    (viewIcon Duotone.trashAlt [])
                ]
            ]
        ]


viewIcon : Icon -> List (Svg.Attribute msg) -> Element msg
viewIcon icon styles =
    html (icon |> Icon.present |> Icon.styled styles |> Icon.view)


viewTooltip : TooltipState -> Element msg
viewTooltip state =
    let
        tt fontColor bgColor label =
            el
                [ Font.size 12
                , Font.color fontColor
                , Background.color bgColor

                --Border.color colors.black
                --, Border.width 1
                , paddingEach
                    { edges
                        | top = 5
                        , bottom = 4
                        , left = 4
                        , right = 4
                    }
                ]
                (text label)
    in
    case state of
        Off ->
            none

        On tooltip ->
            case tooltip of
                Delete ->
                    tt colors.offWhite colors.lightRed "Delete Item"

                Edit ->
                    tt colors.black colors.bananaMania "Edit Item"



--el
--    [ Font.size 12
--    , Font.color colors.offWhite
--    , Background.color colors.lightRed
--    --Border.color colors.black
--    --, Border.width 1
--    , paddingEach
--        { edges
--            | top = 5
--            , bottom = 4
--            , left = 4
--            , right = 4
--        }
--    ]
--    (text "Delete Item")
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
