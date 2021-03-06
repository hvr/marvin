{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE FunctionalDependencies     #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE TemplateHaskell            #-}
module Marvin.Internal.Types where


import           Control.Arrow           ((&&&))
import           Control.Lens
import           Control.Monad
import           Control.Monad.IO.Class
import           Data.Aeson
import           Data.Aeson.TH
import           Data.Char               (isAlphaNum, isLetter)
import qualified Data.Configurator.Types as C
import           Data.Hashable
import           Data.String
import           Data.Text               (Text, pack, toUpper, unpack)
import qualified System.Log.Logger       as L
import           Text.Read               (readMaybe)


newtype User = User String deriving (IsString, Eq, Hashable)
newtype Channel = Channel String deriving (IsString, Eq, Show, Hashable)


deriveJSON defaultOptions { unwrapUnaryRecords = True } ''User
deriveJSON defaultOptions { unwrapUnaryRecords = True } ''Channel


newtype TimeStamp = TimeStamp { unwrapTimeStamp :: Double } deriving Show


data Message = Message
    { sender    :: User
    , channel   :: Channel
    , content   :: String
    , timestamp :: TimeStamp
    }


instance FromJSON TimeStamp where
    parseJSON (String s) = maybe mzero (return . TimeStamp) $ readMaybe (unpack s)
    parseJSON _          = mzero

instance ToJSON TimeStamp where
    toJSON = toJSON . show . unwrapTimeStamp


-- | A type, basically a String, which identifies a script to the config and the logging facilities.
newtype ScriptId = ScriptId { unwrapScriptId :: Text } deriving (Show, Eq)


-- | A type, basically a String, which identifies an adapter to the config and the logging facilities.
newtype AdapterId a = AdapterId { unwrapAdapterId :: Text } deriving (Show, Eq)


applicationScriptId :: ScriptId
applicationScriptId = ScriptId "bot"


verifyIdString :: String -> (String -> a) -> String -> a
verifyIdString name _ "" = error $ name ++ " must not be empty"
verifyIdString name f s@(x:xs)
    | isLetter x && all (\c -> isAlphaNum c || c == '-' || c == '_' ) xs = f s
    | otherwise = error $ "first character of " ++ name ++ " must be a letter, all other characters can be alphanumeric, '-' or '_'"


instance IsString ScriptId where
    fromString = verifyIdString "script id" (ScriptId . fromString)


instance IsString (AdapterId a) where
    fromString = verifyIdString "adapter id" (AdapterId . fromString)


class HasScriptId s a | s -> a where
    scriptId :: Lens' s a


-- | Denotes a place from which we may access the configuration.
--
-- During script definition or when handling a request we can obtain the config with 'getConfigVal' or 'requireConfigVal'.
class (IsScript m, MonadIO m) => HasConfigAccess m where
    getConfigInternal :: m C.Config


class IsScript m where
    getScriptId :: m ScriptId


prioMapping :: [(Text, L.Priority)]
prioMapping = map ((pack . show) &&& id) [L.DEBUG, L.INFO, L.NOTICE, L.WARNING, L.ERROR, L.CRITICAL, L.ALERT, L.EMERGENCY]


instance C.Configured L.Priority where
    convert (C.String s) = lookup (toUpper s) prioMapping
    convert _            = Nothing

