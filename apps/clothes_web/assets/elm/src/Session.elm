module Session exposing
    ( Api
    , Session
    , User
    , endpoints
    , fromFlags
    , navKey
    , userId
    , userName
    )

import Browser.Navigation as Nav


type Session
    = LoggedIn Nav.Key Api User
    | Guest Nav.Key Api



--type alias Nav =
--    List NavEntry
--type alias NavEntry =
--    { target : String
--    , name : String
--    }


type alias User =
    { name : String
    , id : String
    }


type alias Api =
    { items : String
    , wear : String
    }


navKey : Session -> Nav.Key
navKey session =
    case session of
        LoggedIn key _ _ ->
            key

        Guest key _ ->
            key


endpoints : Session -> Api
endpoints session =
    case session of
        LoggedIn _ api _ ->
            api

        Guest _ api ->
            api



--navigation : Session -> Nav
--navigation session =
--    case session of
--        LoggedIn _ _ nav _ ->
--            nav
--        Guest _ _ nav ->
--            nav


userId : Session -> Maybe String
userId session =
    case session of
        LoggedIn _ _ user ->
            Just user.id

        Guest _ _ ->
            Nothing


userName : Session -> Maybe String
userName session =
    case session of
        LoggedIn _ _ user ->
            Just user.name

        Guest _ _ ->
            Nothing


fromFlags :
    Nav.Key
    -> { user : Maybe User, api : Api }
    -> Session
fromFlags key { user, api } =
    case user of
        Just viewer ->
            LoggedIn key api viewer

        Nothing ->
            Guest key api
