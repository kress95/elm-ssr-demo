module App exposing
    ( Model, init, reuse, encode
    , Msg(..), update, subscriptions
    , ready, title, view
    )

{-|

@docs Model, init, reuse, encode
@docs Msg, update, subscriptions
@docs ready, title, view

-}

import Browser exposing (UrlRequest)
import Dual.Html exposing (..)
import Dual.Html.Attributes exposing (..)
import Dual.Html.Events exposing (onInput)
import Eff exposing (Eff)
import Headers exposing (Headers)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Query.User as User
import Response exposing (Response)
import Url exposing (Url)



-- MODEL


type alias Model =
    { url : Url
    , headers : Headers
    , ready : Bool
    , name : String
    , password : String
    , passwordAgain : String
    }


init : Url -> Headers -> ( Model, Eff Msg )
init url headers =
    ( { url = url
      , headers = headers
      , ready = False
      , name = ""
      , password = ""
      , passwordAgain = ""
      }
    , Eff.query Loaded User.query
    )


reuse : Value -> Url -> ( Model, Eff Msg )
reuse flags url =
    case Decode.decodeValue (decoder url) flags of
        Ok model ->
            ( model, Eff.none )

        Err _ ->
            -- TODO: send error back
            init url Headers.empty


decoder : Url -> Decoder Model
decoder url =
    Decode.succeed Model
        |> Decode.hardcoded url
        |> Decode.required "headers" Headers.decoder
        |> Decode.required "ready" Decode.bool
        |> Decode.required "name" Decode.string
        |> Decode.required "password" Decode.string
        |> Decode.required "passwordAgain" Decode.string


encode : Model -> Value
encode model =
    Encode.object
        [ ( "headers", Headers.encoder model.headers )
        , ( "ready", Encode.bool model.ready )
        , ( "name", Encode.string model.name )
        , ( "password", Encode.string model.password )
        , ( "passwordAgain", Encode.string model.passwordAgain )
        ]



-- UPDATE


type Msg
    = UrlChange Url
    | UrlRequest UrlRequest
    | Name String
    | Password String
    | PasswordAgain String
    | Loaded (Response User.Data)


update : Msg -> Model -> ( Model, Eff Msg )
update msg model =
    case msg of
        UrlChange url ->
            ( { model | url = url }, Eff.none )

        UrlRequest _ ->
            ( model, Eff.none )

        Name name ->
            ( { model | name = name }, Eff.none )

        Password password ->
            ( { model | password = password }, Eff.none )

        PasswordAgain password ->
            ( { model | passwordAgain = password }, Eff.none )

        Loaded (Ok data) ->
            ( { model
                | ready = True
                , name = data.name
                , password = data.password
                , passwordAgain = data.passwordAgain
              }
            , Eff.none
            )

        Loaded (Err _) ->
            -- TODO: report error through log port
            ( model, Eff.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


ready : Model -> Bool
ready model =
    model.ready


title : Model -> String
title _ =
    "Example Title"


view : Model -> Html Msg
view model =
    div []
        [ viewInput "text" "Name" model.name Name
        , viewInput "password" "Password" model.password Password
        , viewInput "password" "Re-enter Password" model.passwordAgain PasswordAgain
        , viewValidation model
        ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg ] []


viewValidation : Model -> Html msg
viewValidation model =
    if model.password == model.passwordAgain then
        div [ style "color" "green" ] [ text "OK" ]

    else
        div [ style "color" "red" ] [ text "Passwords do not match!" ]
