{-|
Module      : $Header$
Description : Marvin the modular bot
Copyright   : (c) Justus Adam, 2016
License     : BSD3
Maintainer  : dev@justus.science
Stability   : experimental
Portability : POSIX

-}
module Marvin
    ( -- * Scripts
      Script, defineScript, ScriptInit
    , ScriptId
    , ScriptDefinition
    , IsAdapter
      -- * Reacting
    , hear, respond, send, reply, messageRoom
    , getMessage, getMatch
    , Message(..), User(..), Room(..)
    , getConfigVal, requireConfigVal
    , BotReacting
    , MessageReactionData, messageField, matchField
    ) where


import           Marvin.Adapter  (IsAdapter)
import           Marvin.Internal
import           Marvin.Types
