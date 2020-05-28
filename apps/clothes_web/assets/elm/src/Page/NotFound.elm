module Page.NotFound exposing (view)

import Element exposing (Attribute, Element, el, text)



-- VIEW


view :
    { title : String
    , attributes : List (Attribute msg)
    , content : Element msg
    }
view =
    { title = "Page Not Found"
    , attributes = []
    , content = el [] (text "Not Found")
    }
