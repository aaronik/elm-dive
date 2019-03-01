module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http exposing (..)
import Json.Encode as Encode



-- HELPERS


fetchNetworks : Cmd Msg
fetchNetworks =
    Http.get
        { url = "/networks"
        , expect = Http.expectString FetchedNetworks
        }


networkDataJsonEncoder : String -> String -> Encode.Value
networkDataJsonEncoder ssid password =
    Encode.object
        [ ( "ssid", Encode.string ssid )
        , ( "password", Encode.string password )
        ]


joinNetwork : String -> String -> Cmd Msg
joinNetwork ssid password =
    Http.post
        { url = "/join"
        , body = Http.jsonBody (networkDataJsonEncoder ssid password)
        , expect = Http.expectString JoinedNetwork
        }


justString : Maybe String -> String
justString string =
    case string of
        Nothing ->
            ""

        Just str ->
            str


spaceFilter : String -> Bool
spaceFilter string =
    string /= ""


networkTextLineToSSID : String -> String
networkTextLineToSSID line =
    justString (List.head (List.filter spaceFilter (String.split " " line)))


networksToUl : String -> Html Msg
networksToUl networks =
    ul []
        (List.map
            (\line -> li [ onClick (ClickNetwork (networkTextLineToSSID line)) ] [ text line ])
            -- reverse / drop / reverse is to remove the last item, an empty item
            (List.reverse (List.drop 1 (List.reverse (String.lines networks))))
        )



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type State
    = Failure
    | Loading
    | GotNetworks
    | RequestingPassword
    | Joined


type alias Model =
    { networkList : String
    , ssid : String
    , password : String
    , message : String
    , state : State
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { networkList = ""
      , ssid = ""
      , password = ""
      , message = ""
      , state = Loading
      }
    , fetchNetworks
    )


type Msg
    = FetchNetworks
    | FetchedNetworks (Result Http.Error String)
    | ClickNetwork String
    | UpdatePassword String
    | JoinNetwork
    | JoinedNetwork (Result Http.Error String)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchNetworks ->
            ( { model | state = Loading, message = "Fetching networks..." }, fetchNetworks )

        FetchedNetworks result ->
            case result of
                Ok networkList ->
                    ( { model | networkList = networkList, state = GotNetworks }, Cmd.none )

                Err _ ->
                    ( { model | state = Failure }, Cmd.none )

        ClickNetwork ssid ->
            ( { model | ssid = ssid, state = RequestingPassword }, Cmd.none )

        UpdatePassword password ->
            ( { model | password = password }, Cmd.none )

        JoinNetwork ->
            ( { model | state = Loading, message = "Attempting to join network..." }, joinNetwork model.ssid model.password )

        JoinedNetwork result ->
            case result of
                Ok ssid ->
                    ( { model | state = Joined }, Cmd.none )

                Err _ ->
                    ( { model | state = Failure, message = "Unable to join network!" }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        Failure ->
            div []
                [ text model.message
                , button [ onClick FetchNetworks ] [ text "refresh" ]
                ]

        Loading ->
            text model.message

        GotNetworks ->
            div []
                [ networksToUl model.networkList
                , button [ onClick FetchNetworks ] [ text "refresh" ]
                ]

        RequestingPassword ->
            div []
                [ input [ placeholder ("Enter password for " ++ model.ssid), onInput UpdatePassword ] []
                , button [ onClick JoinNetwork ] [ text "join network" ]
                ]

        Joined ->
            div []
                [ p [] [ text ("Joined: " ++ model.ssid ++ " successfully!") ]
                , button [ onClick FetchNetworks ] [ text "refresh" ]
                ]
