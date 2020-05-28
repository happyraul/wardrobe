module Page exposing (Page(..), colors, edges, view, viewIcon)

import Browser
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FontAwesome.Duotone as Duotone
import FontAwesome.Icon as Icon exposing (Icon)
import FontAwesome.Regular as Regular
import FontAwesome.Styles as Icon
import Html.Attributes
import Http
import Session
import Svg
import Url.Builder as Builder


{-| Determines which navbar link (if any) will be rendered as active.
Note that we don't enumerate every page here, because the navbar doesn't
have links for every page. Anything that's not part of the navbar falls
under Other.
-}
type Page
    = Other
    | Guest
    | Login
    | Register
    | Home



--logout : Session.Urls -> Cmd Msg
--logout urls =
--    Http.post
--        { url = urls.logout
--        , body = Http.emptyBody
--        , expect = Http.expectWhatever LoggedOut
--        }
---- UPDATE
--type Msg
--    = ClickedLogout
--    | LoggedOut (Result Http.Error ())
--update : Session.Session -> Msg -> Cmd Msg
--update session msg =
--    case msg of
--        ClickedLogout ->
--            logout (Session.endpoints session)
--        LoggedOut (Ok ()) ->
--            let
--                urls =
--                    Session.endpoints session
--            in
--            Nav.load <|
--                Builder.relative
--                    [ urls.less ]
--                    [ Builder.string "home" "index" ]
--        LoggedOut (Err error) ->
--            Cmd.none
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


viewIcon : Icon.Icon -> List (Svg.Attribute msg) -> Element msg
viewIcon icon styles =
    html (icon |> Icon.present |> Icon.styled styles |> Icon.view)


view :
    Session.Session
    -> Page
    ->
        { title : String
        , attributes : List (Attribute subMsg)
        , content : Element subMsg
        }
    -> (subMsg -> msg)
    -> Browser.Document msg
view session page { title, attributes, content } toMsg =
    Browser.Document ("Wardrobe | " ++ title)
        [ Icon.css
        , layout
            ([ paddingEach { edges | top = 20, left = 30, right = 30 } ]
                ++ List.map (mapAttribute toMsg) attributes
            )
          <|
            column [ spacing 10, width (maximum 1166 fill), centerX ] <|
                [ row [ width fill ]
                    [ el [ Font.size 36 ] (text "Wardrobe")
                    ]
                , map toMsg content
                ]
        ]



--viewSession : Session.Session -> List (Element Msg)
--viewSession session =
--    case Session.email session of
--        Just email ->
--            [ el [ Font.size 12, alignRight ] (text email)
--            , viewLogoutButton
--            ]
--        Nothing ->
--            []
--viewLogoutButton : Element Msg
--viewLogoutButton =
--    Input.button
--        [ Background.color colors.white
--        , height (px 38)
--        , width (px 150)
--        , Border.color colors.lightgrey
--        , Border.width 1
--        , Border.solid
--        , Border.rounded 4
--        ]
--        { onPress = Just ClickedLogout
--        , label =
--            row [ width fill ]
--                [ el
--                    [ paddingEach { edges | left = 10, right = 21 } ]
--                    (viewIcon Duotone.signOutAlt [])
--                , el
--                    [ Font.size 11
--                    , Font.letterSpacing 1
--                    , Font.bold
--                    , Font.center
--                    , htmlAttribute <|
--                        Html.Attributes.style "text-transform" "uppercase"
--                    ]
--                    (text "Logout")
--                ]
--}



--viewNavigation : List Session.NavEntry -> Page -> Element msg
--viewNavigation navigation page =
--    let
--        viewButton =
--            viewNavButton page
--    in
--    row [ spacing 4 ] (List.map viewButton navigation)
--viewNavButton : Page -> Session.NavEntry -> Element msg
--viewNavButton current entry =
--    let
--        page =
--            case current of
--                Translations ->
--                    "modify translations"
--                Tags ->
--                    "manage tags"
--                Engineers ->
--                    "engineers"
--                Other ->
--                    "not found"
--        attributes =
--            if String.toLower entry.name == Debug.log "page" page then
--                { bgColor = Background.color colors.primary
--                , fontColor = Font.color colors.white
--                , borderColor = Border.color colors.primary
--                }
--            else
--                { bgColor = Background.color colors.white
--                , fontColor = Font.color colors.darkgrey
--                , borderColor = Border.color colors.lightgrey
--                }
--    in
--    el
--        [ height (px 38)
--        , attributes.bgColor
--        , width (px 180)
--        , attributes.borderColor
--        , Border.width 1
--        , Border.solid
--        , Border.rounded 4
--        ]
--    <|
--        link
--            [ Font.size 11
--            , Font.letterSpacing 1
--            , Font.bold
--            , Font.center
--            , attributes.fontColor
--            , width (px 180)
--            , paddingXY 0 13
--            , htmlAttribute (Html.Attributes.style "text-transform" "uppercase")
--            , centerY
--            ]
--            { url = entry.target, label = text entry.name }
