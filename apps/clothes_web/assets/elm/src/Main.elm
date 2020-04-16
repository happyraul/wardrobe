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
    { id : String
    , color : String
    , name : String
    , state : ItemState
    }


type ItemState
    = ModeEdit
    | ModeView


swapState : String -> ClothingItem -> ClothingItem
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
    , colorEditInput : String
    , nameEditInput : String
    , showTooltip : TooltipState
    , mousePosition : ( Float, Float )
    }


type TooltipState
    = Off
    | On Tooltip


type Tooltip
    = Delete
    | Edit
    | Save


type ItemAttribute
    = Color
    | Name


type FormInput
    = NewItem ItemAttribute
    | EditItem ItemAttribute


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
        -- colorEditInput
        ""
        -- nameEditInput
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
        , body =
            Http.jsonBody
                (itemEncoder
                    { id = Nothing
                    , color = item.color
                    , name = item.name
                    }
                )
        , expect = Http.expectJson ItemAdded (itemDecoder item)
        }


deleteItem : String -> String -> String -> Cmd Msg
deleteItem url userId id =
    Http.request
        { method = "DELETE"
        , headers = []
        , url =
            Builder.relative
                [ url
                , id
                ]
                [ Builder.string "user" userId ]
        , body = Http.emptyBody
        , expect = Http.expectWhatever (ItemDeleted id)
        , timeout = Nothing
        , tracker = Nothing
        }


updateItem : String -> String -> ClothingItem -> Cmd Msg
updateItem url userId item =
    Http.request
        { method = "PATCH"
        , headers = []
        , url =
            Builder.relative
                [ url
                , item.id
                ]
                [ Builder.string "user" userId ]
        , body =
            Http.jsonBody
                (itemEncoder
                    { id = Just item.id
                    , color = item.color
                    , name = item.name
                    }
                )
        , expect = Http.expectWhatever (ItemUpdated item.id)
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
                (Decode.field "id" Decode.string)
                (Decode.field "color" Decode.string)
                (Decode.field "name" Decode.string)
                (Decode.succeed ModeView)


itemDecoder : { color : String, name : String } -> Decode.Decoder ClothingItem
itemDecoder item =
    Decode.field "data" <|
        Decode.map4 ClothingItem
            (Decode.field "id" Decode.string)
            (Decode.succeed item.color)
            (Decode.succeed item.name)
            (Decode.succeed ModeView)


itemEncoder : { id : Maybe String, color : String, name : String } -> Encode.Value
itemEncoder item =
    let
        fields =
            case item.id of
                Just id ->
                    [ ( "id", Encode.string id )
                    , ( "color", Encode.string item.color )
                    , ( "name", Encode.string item.name )
                    ]

                Nothing ->
                    [ ( "color", Encode.string item.color )
                    , ( "name", Encode.string item.name )
                    ]
    in
    Encode.object
        [ ( "data", Encode.object fields ) ]



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
    | DeletePressed String
    | EditPressed ClothingItem
    | SavePressed ClothingItem
    | ItemAdded (Result Http.Error ClothingItem)
    | ItemDeleted String (Result Http.Error ())
    | ItemUpdated String (Result Http.Error ())


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
                NewItem attribute ->
                    case attribute of
                        Color ->
                            ( { model | colorInput = inputValue }, Cmd.none )

                        Name ->
                            ( { model | nameInput = inputValue }, Cmd.none )

                EditItem attribute ->
                    case attribute of
                        Color ->
                            ( { model | colorEditInput = inputValue }, Cmd.none )

                        Name ->
                            ( { model | nameEditInput = inputValue }, Cmd.none )

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
            ( { model | showTooltip = Off }, deleteItem model.api "raul" id )

        EditPressed item ->
            let
                ( color, name ) =
                    case item.state of
                        ModeEdit ->
                            ( "", "" )

                        ModeView ->
                            ( item.color, item.name )
            in
            ( { model
                | clothes = List.map (swapState item.id) model.clothes
                , colorEditInput = color
                , nameEditInput = name
              }
            , Cmd.none
            )

        SavePressed oldItem ->
            ( { model | showTooltip = Off }
            , updateItem model.api
                "raul"
                { oldItem
                    | color = model.colorEditInput
                    , name = model.nameEditInput
                }
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

        ItemUpdated id result ->
            case result of
                Ok () ->
                    let
                        clothes =
                            List.map
                                (\item ->
                                    if item.id == id then
                                        { item
                                            | state = ModeView
                                            , color = model.colorEditInput
                                            , name = model.nameEditInput
                                        }

                                    else
                                        item
                                )
                                model.clothes
                    in
                    ( { model | clothes = clothes }, Cmd.none )

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
                    model.colorEditInput
                    model.nameEditInput
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
            { onChange = TypedInput (NewItem Color)
            , text = colorInput
            , placeholder = viewPlaceholder "enter a color"
            , label = Input.labelAbove [] (text "color")
            }
        , Input.text []
            { onChange = TypedInput (NewItem Name)
            , text = nameInput
            , placeholder = viewPlaceholder "enter a name"
            , label = Input.labelAbove [] (text "name")
            }
        , Input.button [ Border.width 1, Border.color colors.black ]
            { onPress = Just AddPressed
            , label = text "Add Item"
            }
        ]


viewItems : List ClothingItem -> String -> String -> Element Msg
viewItems items editedColor editedName =
    --column [ spacing 3, width fill ] (List.map viewItem items)
    table []
        { data = items
        , columns =
            [ { header = text "Color"
              , width = fillPortion 2
              , view = \{ color, state } -> viewField (viewProperty color state editedColor Color)
              }
            , { header = text "Name"
              , width = fillPortion 3
              , view = \{ name, state } -> viewField (viewProperty name state editedName Name)
              }
            , { header = none
              , width = fillPortion 2
              , view = \item -> viewField (viewSaveButton item)
              }
            , { header = none
              , width = fillPortion 2
              , view = \item -> viewField (viewEditButton item)
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


viewProperty : String -> ItemState -> String -> ItemAttribute -> Element Msg
viewProperty value state editedValue itemAttribute =
    case state of
        ModeView ->
            el
                [ height (px 46)
                , paddingEach { edges | top = 13, left = 13 }
                ]
                (text value)

        ModeEdit ->
            Input.text [ height (px 46) ]
                { onChange = TypedInput (EditItem itemAttribute)
                , text = editedValue
                , placeholder = Nothing
                , label = Input.labelHidden value
                }


viewEditButton : ClothingItem -> Element Msg
viewEditButton item =
    el
        [ mouseOver [ Font.color colors.cadmiumGreen ]
        , Events.onClick <| EditPressed item
        , Events.onMouseEnter (EnteredTooltip Edit)
        , Events.onMouseLeave LeftTooltip
        , centerY
        , centerX
        ]
        (viewIcon Duotone.edit [])


viewSaveButton : ClothingItem -> Element Msg
viewSaveButton item =
    case item.state of
        ModeEdit ->
            el
                [ mouseOver [ Font.color colors.cadmiumGreen ]
                , Events.onClick <| SavePressed item
                , Events.onMouseEnter (EnteredTooltip Save)
                , Events.onMouseLeave LeftTooltip
                , centerY
                , centerX
                ]
                (viewIcon Duotone.save [])

        ModeView ->
            none


viewDeleteButton : String -> Element Msg
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

                Save ->
                    tt colors.offWhite colors.cadmiumGreen "Save Item"



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
