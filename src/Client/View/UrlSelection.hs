{-# Language BangPatterns #-}
{-|
Module      : Client.View.UrlSelection
Description : URL selection module
Copyright   : (c) Eric Mertens, 2016
License     : ISC
Maintainer  : emertens@gmail.com

This module provides a list of the URLs found in the current message
window in order to assist in selecting one to open with @/url@

-}
module Client.View.UrlSelection
  ( urlSelectionView
  ) where

import           Client.State
import           Client.State.Window
import           Client.Image.Message
import           Client.State.Focus
import           Control.Lens
import           Data.Text (Text)
import           Graphics.Vty.Image
import           Text.Read (readMaybe)
import           Text.Regex.TDFA


-- | Generate the lines used for the view when typing @/url@
urlSelectionView ::
  Focus       {- ^ window to search    -} ->
  String      {- ^ argument to command -} ->
  ClientState {- ^ client state        -} ->
  [Image]     {- ^ image lines         -}
urlSelectionView focus arg st =
    zipWith (draw selected) [1..]
         $ toListOf (clientWindows . ix focus . winMessages . each . wlText . folding textUrls) st
  where
    selected
      | all (==' ') arg         = 1
      | Just i <- readMaybe arg = i
      | otherwise               = 0


textUrls :: Text -> [Text]
textUrls = getAllTextMatches . match urlPattern

draw :: Int -> Int -> Text -> Image
draw selected i url = string attr (shows i ". ") <|> text' attr (cleanText url)
  where
    attr | selected == i = withStyle defAttr reverseVideo
         | otherwise     = defAttr