module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Element
import Json.Decode as Decode
import Page
import Page.Home as Home
import Page.NotFound as NotFound
import Route
import Session
import Url



-- MAIN


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }



-- MODEL


type Model
    = NotFound Session.Session
    | Home Home.Model
    | Login Session.Session
    | Register Session.Session
    | Guest Session.Session


type alias Flags =
    { api : Session.Api
    , user : Maybe Session.User
    }


init : Decode.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsJson url navKey =
    let
        flags =
            case Decode.decodeValue flagsDecoder flagsJson of
                Ok decodedFlags ->
                    decodedFlags

                Err error ->
                    Debug.log
                        (Decode.errorToString error)
                        Flags
                        (Session.Api "" "")
                        Nothing
    in
    changeRouteTo
        (Route.fromUrl url)
        (NotFound (Session.fromFlags navKey flags))



-- DECODERS


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.map2 Flags
        (Decode.map2 Session.Api
            (Decode.at [ "api", "items" ] Decode.string)
            (Decode.at [ "api", "wear" ] Decode.string)
        )
        (Decode.maybe
            (Decode.map2 Session.User
                (Decode.at [ "user", "display_name" ] Decode.string)
                (Decode.at [ "user", "id" ] Decode.string)
            )
        )



-- UPDATE


type Msg
    = Ignored
    | ClickedLink Browser.UrlRequest
    | ChangedUrl Url.Url
    | GotHomeMsg Home.Msg


toSession : Model -> Session.Session
toSession page =
    case page of
        NotFound session ->
            session

        Guest session ->
            session

        Login session ->
            session

        Register session ->
            session

        Home clothes ->
            Home.toSession clothes


changeRouteTo : Maybe Route.Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        session =
            toSession model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just Route.Login ->
            ( Login session, Cmd.none )

        Just Route.Register ->
            ( Register session, Cmd.none )

        Just Route.Index ->
            case Session.userId session of
                Just userId ->
                    Home.init session userId
                        |> updateWith Home GotHomeMsg model

                Nothing ->
                    ( Guest session, Nav.load "/" )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Ignored, _ ) ->
            ( model, Cmd.none )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl
                        (Session.navKey (toSession model))
                        (Url.toString url)
                    )

                Browser.External href ->
                    ( model, Nav.load href )

        ( GotHomeMsg subMsg, Home clothes ) ->
            Home.update subMsg clothes
                |> updateWith Home GotHomeMsg model

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


updateWith :
    (subModel -> Model)
    -> (subMsg -> Msg)
    -> Model
    -> ( subModel, Cmd subMsg )
    -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel, Cmd.map toMsg subCmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        NotFound _ ->
            Sub.none

        Login _ ->
            Sub.none

        Register _ ->
            Sub.none

        Guest _ ->
            Sub.none

        Home clothes ->
            Sub.map GotHomeMsg (Home.subscriptions clothes)



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        viewPage :
            Page.Page
            -> (msg -> Msg)
            ->
                { title : String
                , attributes : List (Element.Attribute msg)
                , content : Element.Element msg
                }
            -> Browser.Document Msg
        viewPage page toMsg config =
            Page.view (toSession model) page config toMsg
    in
    case model of
        NotFound _ ->
            NotFound.view
                |> viewPage Page.Other (\_ -> Ignored)

        Guest _ ->
            NotFound.view
                |> viewPage Page.Other (\_ -> Ignored)

        Login _ ->
            NotFound.view
                |> viewPage Page.Other (\_ -> Ignored)

        Register _ ->
            NotFound.view
                |> viewPage Page.Other (\_ -> Ignored)

        Home clothes ->
            Home.view clothes
                |> viewPage Page.Home GotHomeMsg
