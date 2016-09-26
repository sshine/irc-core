{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Client.Network.Connect
Description : Interface to the connection package
Copyright   : (c) Eric Mertens, 2016
License     : ISC
Maintainer  : emertens@gmail.com

This module is responsible for creating 'Connection' values
for a particular server as specified by a 'ServerSettings'.
This involves setting up certificate stores an mapping
network settings from the client configuration into the
network connection library.
-}

module Client.Network.Connect
  ( withConnection
  ) where

import           Client.Configuration
import           Client.Configuration.ServerSettings
import           Control.Exception  (bracket)
import           Control.Lens
import           Control.Monad
import           Data.Default.Class (def)
import           Data.Monoid        ((<>))
import           Network.Socket     (PortNumber)
import           Hookup

buildConnectionParams :: ServerSettings -> ConnectionParams
buildConnectionParams args =
  do let useSecure = case view ssTls args of
                       UseInsecure    -> Nothing
                       UseInsecureTls -> Just (TlsParams Nothing [] True)
                       UseTls         -> Just (TlsParams Nothing [] False)

     let proxySettings = view ssSocksHost args <&> \host ->
                           SocksParams
                             host
                             (view ssSocksPort args)

     ConnectionParams
       { cpHost  = view ssHostName args
       , cpPort  = ircPort args
       , cpTls   = useSecure
       , cpSocks = proxySettings
       }

ircPort :: ServerSettings -> PortNumber
ircPort args =
  case view ssPort args of
    Just p -> fromIntegral p
    Nothing ->
      case view ssTls args of
        UseInsecure -> 6667
        _           -> 6697


-- | Create a new 'Connection' which will be closed when the continuation finishes.
withConnection :: ServerSettings -> (Connection -> IO a) -> IO a
withConnection settings k =
  do let params = buildConnectionParams settings
     bracket (connect params) close k
