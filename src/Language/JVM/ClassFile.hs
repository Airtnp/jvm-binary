{-|
Module      : Language.JVM.ClassFile
Copyright   : (c) Christian Gram Kalhauge, 2017
License     : MIT
Maintainer  : kalhuage@cs.ucla.edu

The class file is described in this module.
-}

{-# LANGUAGE DeriveGeneric #-}
module Language.JVM.ClassFile
  ( ClassFile (..)

  , cAccessFlags
  , cInterfaces
  , cFields
  , cMethods
  , cAttributes

  , cThisClass
  , cSuperClass

  -- * Attributes
  , cBootstrapMethods
  ) where

import           Data.Binary
import           Data.Monoid
import           Data.Set (Set)
import           GHC.Generics            (Generic)

import           Language.JVM.AccessFlag
import           Language.JVM.Attribute  (Attribute, BootstrapMethods,
                                          fromAttribute')
import           Language.JVM.Constant
import           Language.JVM.Field      (Field)
import           Language.JVM.Method     (Method)
import           Language.JVM.Utils

-- | A 'ClassFile' as described
-- [here](http://docs.oracle.com/javase/specs/jvms/se7/html/jvms-4.html).

data ClassFile = ClassFile
  { cMagicNumber     :: !Word32

  , cMinorVersion    :: !Word16
  , cMajorVersion    :: !Word16

  , cConstantPool    :: !ConstantPool

  , cAccessFlags'     :: BitSet16 CAccessFlag

  , cThisClassIndex  :: Index ClassName
  , cSuperClassIndex :: Index ClassName

  , cInterfaces'     :: SizedList16 (Index ClassName)
  , cFields'         :: SizedList16 Field
  , cMethods'        :: SizedList16 Method
  , cAttributes'     :: SizedList16 Attribute
  } deriving (Show, Eq, Generic)

instance Binary ClassFile where

-- | Get the set of access flags
cAccessFlags :: ClassFile -> Set CAccessFlag
cAccessFlags = toSet . cAccessFlags'

-- | Get a list of 'ConstantRef's to interfaces.
cInterfaces :: ClassFile -> [ Index ClassName ]
cInterfaces = unSizedList . cInterfaces'

-- | Get a list of 'Field's of a ClassFile.
cFields :: ClassFile -> [Field]
cFields = unSizedList . cFields'

-- | Get a list of 'Method's of a ClassFile.
cMethods :: ClassFile -> [Method]
cMethods = unSizedList . cMethods'

-- | Lookup the this class in a ConstantPool
cThisClass :: ConstantPool -> ClassFile -> Maybe ClassName
cThisClass cp = deref cp . cThisClassIndex

-- | Lookup the super class in the ConstantPool
cSuperClass :: ConstantPool -> ClassFile -> Maybe ClassName
cSuperClass cp = deref cp . cSuperClassIndex

-- | Get a list of 'Attribute's of a ClassFile.
cAttributes :: ClassFile -> [Attribute]
cAttributes = unSizedList . cAttributes'

-- | Fetch the 'BootstrapMethods' attribute.
-- There can only one bootstrap methods per class, but there might not be
-- one.
cBootstrapMethods :: ConstantPool -> ClassFile -> Maybe (Either String BootstrapMethods)
cBootstrapMethods cp =
  getFirst . foldMap (First . fromAttribute' cp) . cAttributes
