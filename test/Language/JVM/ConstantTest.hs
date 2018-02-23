{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE FlexibleInstances #-}
module Language.JVM.ConstantTest where

import SpecHelper

import Language.JVM.Constant
import Language.JVM.ConstantPool
import Language.JVM.UtilsTest ()

import qualified Data.IntMap as IM

prop_encode_and_decode :: ConstantPool Low -> Property
prop_encode_and_decode = isoBinary

prop_Constant_encode_and_decode :: Constant Low -> Property
prop_Constant_encode_and_decode = isoBinary

instance Arbitrary (Ref a Low) where
  arbitrary =
    RefI <$> arbitrary

instance Arbitrary (DeepRef a Low) where
  arbitrary =
    DeepRef .RefI <$> arbitrary

instance Arbitrary (ConstantPool Low) where
  arbitrary =
    ConstantPool . IM.fromList . go 1 <$> arbitrary
    where
      go n (e : lst) =
        (n, e) : go (n + constantSize e) lst
      go _ [] = []

instance Arbitrary (Constant Low) where
  arbitrary = oneof
    [ CString <$> arbitrary
    , CInteger <$> arbitrary
    , CFloat <$> arbitrary
    , CLong <$> arbitrary
    , CDouble <$> arbitrary
    , CClassRef <$> arbitrary
    , CStringRef <$> arbitrary
    , CFieldRef <$> arbitrary
    , CMethodRef <$> arbitrary
    , CInterfaceMethodRef <$> arbitrary
    , CNameAndType <$> arbitrary <*> arbitrary
    , CMethodHandle <$> arbitrary
    , CMethodType <$> arbitrary
    , CInvokeDynamic <$> arbitrary
    ]

instance (Arbitrary (a Low)) => Arbitrary (InClass a Low) where
  arbitrary = InClass <$> arbitrary <*> arbitrary

instance Arbitrary (FieldId Low) where
  arbitrary = FieldId <$> arbitrary <*> arbitrary

instance Arbitrary (MethodId Low) where
  arbitrary = MethodId <$> arbitrary <*> arbitrary

instance Arbitrary (MethodHandle Low) where
  arbitrary =
    oneof
      [ MHField <$> ( MethodHandleField <$> arbitrary <*> arbitrary)
      , MHMethod <$> ( MethodHandleMethod <$> arbitrary <*> arbitrary)
      , MHInterface <$> ( MethodHandleInterface <$> arbitrary)
      ]

instance Arbitrary MethodHandleFieldKind where
  arbitrary =
    oneof [ pure x | x <- [ MHGetField, MHGetStatic, MHPutField, MHPutStatic ] ]

instance Arbitrary MethodHandleMethodKind where
  arbitrary =
    oneof [ pure x | x <- [ MHInvokeVirtual , MHInvokeStatic , MHInvokeSpecial , MHNewInvokeSpecial ] ]

instance Arbitrary (InvokeDynamic Low) where
  arbitrary = InvokeDynamic <$> arbitrary <*> arbitrary
