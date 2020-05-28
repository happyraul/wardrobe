module Route exposing (Route(..), fromUrl)

import Url
import Url.Parser as Parser exposing ((</>))



-- ROUTING


type Route
    = Index
    | Login
    | Register


parser : Parser.Parser (Route -> a) a
parser =
    Parser.oneOf
        [ route Index Parser.top
        , route Login (Parser.s "login" </> Parser.top)
        , route Register (Parser.s "register" </> Parser.top)
        ]


route : a -> Parser.Parser a Route -> Parser.Parser (Route -> c) c
route handler parse =
    Parser.map handler parse


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    Parser.parse parser url
