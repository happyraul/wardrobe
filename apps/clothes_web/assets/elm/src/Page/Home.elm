module Page.Home exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , view
    )

import Browser.Events as BE
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import FontAwesome.Duotone as Duotone
import Html.Events
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Page exposing (edges)
import Session
import Url.Builder as Builder



-- MODEL


type alias Model =
    { session : Session.Session
    , userId : String
    , clothes : List ClothingItem
    , colorInput : String
    , nameInput : String
    , colorEditInput : String
    , nameEditInput : String
    , showTooltip : TooltipState
    , mousePosition : ( Float, Float )
    }


type alias ClothingItem =
    { id : String
    , color : String
    , name : String
    , lastWorn : String
    , wearCount : Int
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


init : Session.Session -> String -> ( Model, Cmd Msg )
init session userId =
    let
        api =
            Session.endpoints session
    in
    ( Model session
        -- userId
        userId
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
    , requestClothes api.items userId
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


wearItem : String -> String -> String -> Cmd Msg
wearItem url userId id =
    Http.post
        { url = Builder.relative [ url ] [ Builder.string "user" userId ]
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "data"
                      , Encode.object [ ( "id", Encode.string id ) ]
                      )
                    ]
                )
        , expect = Http.expectJson (ItemWorn id) lastWornDecoder
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


clothingItemsDecoder : Decode.Decoder (List ClothingItem)
clothingItemsDecoder =
    Decode.field "data" <|
        Decode.list <|
            Decode.map6 ClothingItem
                (Decode.field "id" Decode.string)
                (Decode.field "color" Decode.string)
                (Decode.field "name" Decode.string)
                (Decode.oneOf
                    [ Decode.field "last_worn" Decode.string
                    , Decode.succeed ""
                    ]
                )
                (Decode.oneOf
                    [ Decode.field "wear_count" Decode.int
                    , Decode.succeed 0
                    ]
                )
                (Decode.succeed ModeView)


lastWornDecoder : Decode.Decoder String
lastWornDecoder =
    Decode.field "data" <|
        Decode.field "last_worn" Decode.string


itemDecoder : { color : String, name : String } -> Decode.Decoder ClothingItem
itemDecoder item =
    Decode.field "data" <|
        Decode.map6 ClothingItem
            (Decode.field "id" Decode.string)
            (Decode.succeed item.color)
            (Decode.succeed item.name)
            (Decode.succeed "")
            (Decode.succeed 0)
            (Decode.succeed ModeView)


itemEncoder :
    { id : Maybe String, color : String, name : String }
    -> Encode.Value
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
    = ClothesLoaded (Result Http.Error (List ClothingItem))
    | TypedInput FormInput String
    | KeyDown Int
    | MouseMoved ( Float, Float )
    | EnteredTooltip Tooltip
    | LeftTooltip
    | AddPressed
    | WearPressed String
    | DeletePressed String
    | EditPressed ClothingItem
    | SavePressed ClothingItem
    | ItemAdded (Result Http.Error ClothingItem)
    | ItemWorn String (Result Http.Error String)
    | ItemDeleted String (Result Http.Error ())
    | ItemUpdated String (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        api =
            Session.endpoints model.session
    in
    case msg of
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
                            ( { model | colorEditInput = inputValue }
                            , Cmd.none
                            )

                        Name ->
                            ( { model | nameEditInput = inputValue }
                            , Cmd.none
                            )

        KeyDown key ->
            if key == 13 && model.colorInput /= "" && model.nameInput /= "" then
                ( { model | colorInput = "", nameInput = "" }
                , addItem api.items
                    model.userId
                    { color = model.colorInput
                    , name = model.nameInput
                    }
                )

            else
                ( model, Cmd.none )

        MouseMoved pos ->
            ( { model | mousePosition = pos }, Cmd.none )

        EnteredTooltip tooltip ->
            ( { model | showTooltip = On tooltip }, Cmd.none )

        LeftTooltip ->
            ( { model | showTooltip = Off }, Cmd.none )

        AddPressed ->
            ( { model | colorInput = "", nameInput = "" }
            , addItem api.items
                model.userId
                { color = model.colorInput
                , name = model.nameInput
                }
            )

        WearPressed id ->
            ( model, wearItem api.wear model.userId id )

        DeletePressed id ->
            ( { model | showTooltip = Off }
            , deleteItem api.items model.userId id
            )

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
            , updateItem api.items
                model.userId
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

        ItemWorn id result ->
            case result of
                Ok lastWorn ->
                    let
                        clothes =
                            List.map
                                (\item ->
                                    if item.id == id then
                                        { item
                                            | lastWorn = lastWorn
                                            , wearCount = item.wearCount + 1
                                        }

                                    else
                                        item
                                )
                                model.clothes
                    in
                    ( { model | clothes = clothes }, Cmd.none )

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


view :
    Model
    ->
        { title : String
        , attributes : List (Attribute Msg)
        , content : Element Msg
        }
view model =
    let
        name =
            Maybe.withDefault "Nobody" (Session.userName model.session)
    in
    { title = "Home"
    , attributes =
        [ inFront
            (el
                [ moveRight (Tuple.first model.mousePosition + 20.0)
                , moveDown (Tuple.second model.mousePosition - 5.0)
                ]
                (viewTooltip model.showTooltip)
            )
        ]
    , content =
        column [ width fill ]
            [ text "My Clothes"
            , viewForm model.colorInput model.nameInput
            , text (name ++ "'s clothes")
            , viewItems model.clothes
                model.colorEditInput
                model.nameEditInput
            ]
    }


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    htmlAttribute <|
        Html.Events.on "keydown" (Decode.map tagger Html.Events.keyCode)


viewForm : String -> String -> Element Msg
viewForm colorInput nameInput =
    let
        viewPlaceholder placeholder =
            Just (Input.placeholder [] (text placeholder))
    in
    row []
        [ Input.text [ onKeyDown KeyDown ]
            { onChange = TypedInput (NewItem Color)
            , text = colorInput
            , placeholder = viewPlaceholder "enter a color"
            , label = Input.labelAbove [] (text "color")
            }
        , Input.text [ onKeyDown KeyDown ]
            { onChange = TypedInput (NewItem Name)
            , text = nameInput
            , placeholder = viewPlaceholder "enter a name"
            , label = Input.labelAbove [] (text "name")
            }
        , Input.button [ Border.width 1, Border.color Page.colors.black ]
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
            [ { header = none
              , width = fillPortion 1
              , view = \{ id } -> viewField (viewWearButton id)
              }
            , { header = text "Color"
              , width = fillPortion 2
              , view =
                    \{ color, state } ->
                        viewField (viewProperty color state editedColor Color)
              }
            , { header = text "Name"
              , width = fillPortion 3
              , view =
                    \{ name, state } ->
                        viewField (viewProperty name state editedName Name)
              }
            , { header = text "Worn"
              , width = fillPortion 2
              , view =
                    \{ wearCount } ->
                        let
                            message : String
                            message =
                                if wearCount == 0 then
                                    "Never worn"

                                else if wearCount == 1 then
                                    "Worn once"

                                else
                                    "Worn "
                                        ++ String.fromInt wearCount
                                        ++ " times"
                        in
                        viewField (text message)
              }
            , { header = text "Last Worn"
              , width = fillPortion 3
              , view = \{ lastWorn } -> viewField (text lastWorn)
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
        , height (px 46)
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
        [ mouseOver [ Font.color Page.colors.cadmiumGreen ]
        , Events.onClick <| EditPressed item
        , Events.onMouseEnter (EnteredTooltip Edit)
        , Events.onMouseLeave LeftTooltip
        , centerY
        , centerX
        ]
        (Page.viewIcon Duotone.edit [])


viewSaveButton : ClothingItem -> Element Msg
viewSaveButton item =
    case item.state of
        ModeEdit ->
            el
                [ mouseOver [ Font.color Page.colors.cadmiumGreen ]
                , Events.onClick <| SavePressed item
                , Events.onMouseEnter (EnteredTooltip Save)
                , Events.onMouseLeave LeftTooltip
                , centerY
                , centerX
                ]
                (Page.viewIcon Duotone.save [])

        ModeView ->
            none


viewDeleteButton : String -> Element Msg
viewDeleteButton id =
    el
        [ pointer
        , mouseOver [ Font.color Page.colors.warning ]
        , Events.onClick <| DeletePressed id
        , Events.onMouseEnter (EnteredTooltip Delete)
        , Events.onMouseLeave LeftTooltip
        , centerY
        ]
        (Page.viewIcon Duotone.trashAlt [])


viewTooltip : TooltipState -> Element msg
viewTooltip state =
    let
        tt fontColor bgColor label =
            el
                [ Font.size 12
                , Font.color fontColor
                , Background.color bgColor

                --Border.color Page.colors.black
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
                    tt Page.colors.offWhite Page.colors.lightRed "Delete Item"

                Edit ->
                    tt Page.colors.black Page.colors.bananaMania "Edit Item"

                Save ->
                    tt Page.colors.offWhite Page.colors.cadmiumGreen "Save Item"


viewWearButton : String -> Element Msg
viewWearButton itemId =
    Input.button [ Border.width 1, Border.color Page.colors.black ]
        { onPress = Just (WearPressed itemId)
        , label = text "Wear it!"
        }



-- EXPORT


toSession : Model -> Session.Session
toSession model =
    model.session
