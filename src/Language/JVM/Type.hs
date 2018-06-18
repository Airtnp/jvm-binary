{-|
Module      : Language.JVM.Type
Copyright   : (c) Christian Gram Kalhauge, 2018
License     : MIT
Maintainer  : kalhuage@cs.ucla.edu

This module contains the 'JType', 'ClassName', 'MethodDescriptor', and
'FieldDescriptor'.
-}
{-# LANGUAGE DeriveAnyClass       #-}
{-# LANGUAGE DeriveGeneric        #-}
{-# LANGUAGE OverloadedStrings    #-}
module Language.JVM.Type
  (
  -- * Base types
  -- ** ClassName
    ClassName (..)
  , strCls
  , dotCls

  -- ** JType
  , JType (..)
  , JBaseType (..)

  -- ** MethodDescriptor
  , MethodDescriptor (..)

  -- ** FieldDescriptor
  , FieldDescriptor (..)

  -- ** NameAndType
  , NameAndType (..)
  , (<:>)

  , TypeParse (..)
  ) where

import           Control.DeepSeq      (NFData)
import           Data.Attoparsec.Text
import           Data.String
import qualified Data.Text            as Text
import           GHC.Generics         (Generic)
import           Prelude              hiding (takeWhile)

-- | A class name
newtype ClassName = ClassName
  { classNameAsText :: Text.Text
  } deriving (Eq, Ord, Generic, NFData)

instance Show ClassName where
  show = show . classNameAsText

-- | Wrapper method that converts a string representation of a class into
-- a class.
strCls :: String -> ClassName
strCls = dotCls . Text.pack

-- | Takes the dot representation and converts it into a class.
dotCls :: Text.Text -> ClassName
dotCls = ClassName . Text.intercalate "/" . Text.splitOn "."

-- | The Jvm Primitive Types
data JBaseType
  = JTByte
  | JTChar
  | JTDouble
  | JTFloat
  | JTInt
  | JTLong
  | JTShort
  | JTBoolean
  deriving (Show, Eq, Ord, Generic, NFData)

-- | The JVM types
data JType
  = JTBase JBaseType
  | JTClass ClassName
  | JTArray JType
  deriving (Show, Eq, Ord, Generic, NFData)

-- | Method Descriptor
data MethodDescriptor = MethodDescriptor
  { methodDescriptorArguments  :: [JType]
  , methodDescriptorReturnType :: Maybe JType
  } deriving (Show, Ord, Eq, Generic, NFData)

-- | Field Descriptor
newtype FieldDescriptor = FieldDescriptor
  { fieldDescriptorType :: JType
  } deriving (Show, Ord, Eq, Generic, NFData)

-- | A name and a type
data NameAndType a = NameAndType
  { ntName       :: Text.Text
  , ntDescriptor :: a
  } deriving (Show, Eq, Ord, Generic, NFData)

(<:>) :: Text.Text -> a -> NameAndType a
(<:>) = NameAndType

class TypeParse a where
  fromText :: Text.Text -> Either String a
  fromText = parseOnly parseText
  parseText :: Parser a
  toText :: a -> Text.Text

instance TypeParse JType where
  parseText = try $ do
    s <- anyChar
    case s :: Char of
      'B' -> return $ JTBase JTByte
      'C' -> return $ JTBase JTChar
      'D' -> return $ JTBase JTDouble
      'F' -> return $ JTBase JTFloat
      'I' -> return $ JTBase JTInt
      'J' -> return $ JTBase JTLong
      'L' -> do
        txt <- takeWhile (/= ';')
        _ <- char ';'
        return $ JTClass (ClassName txt)
      'S' -> return $ JTBase JTShort
      'Z' -> return $ JTBase JTBoolean
      '[' -> JTArray <$> parseText
      _ -> fail $ "Unknown char " ++ show s
  toText tp =
    Text.pack $ go tp ""
    where
      go x =
        case x of
          JTBase y               -> textbase y
          JTClass (ClassName cn) -> ((('L':Text.unpack cn) ++ ";") ++)
          JTArray tp'            -> ('[':) . go tp'
      textbase y =
        case y of
          JTByte    -> ('B':)
          JTChar    -> ('C':)
          JTDouble  -> ('D':)
          JTFloat   -> ('F':)
          JTInt     -> ('I':)
          JTLong    -> ('J':)
          JTShort   -> ('S':)
          JTBoolean -> ('Z':)

instance TypeParse MethodDescriptor where
  toText md =
    Text.concat (
      ["("]
      ++ map toText (methodDescriptorArguments md)
      ++ [")", maybe "V" toText $ methodDescriptorReturnType md ]
    )
  parseText = do
    _ <- char '('
    args <- many' parseText <?> "method arguments"
    _ <- char ')'
    returnType <- choice
      [ char 'V' >> return Nothing
      , Just <$> parseText
      ] <?> "return type"
    return $ MethodDescriptor args returnType

instance TypeParse FieldDescriptor where
  parseText = FieldDescriptor <$> parseText
  toText (FieldDescriptor t) = toText t

instance TypeParse t => TypeParse (NameAndType t)  where
  parseText = do
    name <- many1 $ notChar ':'
    _ <- char ':'
    _type <- parseText
    return $ NameAndType (Text.pack name) _type
  toText (NameAndType name _type) =
    Text.concat [ name , ":" , toText _type ]

fromString' ::
  TypeParse t
  => String
  -> t
fromString' =
  either (error . ("Failed " ++)) id . fromText . Text.pack

instance IsString ClassName where
  fromString = strCls

instance IsString JType where
  fromString = fromString'

instance IsString FieldDescriptor where
  fromString = fromString'

instance IsString MethodDescriptor where
  fromString = fromString'

instance TypeParse t => IsString (NameAndType t) where
  fromString = fromString'
