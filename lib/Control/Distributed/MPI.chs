{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# OPTIONS_GHC -Wno-type-defaults #-}

#include <mpi.h>
#include <mpihs.h>

module Control.Distributed.MPI
  ( Comm(..)
  , ComparisonResult(..)
  , Count(..)
  , fromCount
  , toCount
  , Datatype(..)
  , Op(..)
  , Rank(..)
  , fromRank
  , rootRank
  , toRank
  , Request(..)
  , Status(..)
  --, statusError
  , getSource
  , getTag
  , Tag(..)
  , fromTag
  , toTag
  , unitTag
  , ThreadSupport(..)

  , commNull
  , commSelf
  , commWorld
  -- TODO: use a module for this namespace
  , datatypeNull
  , datatypeByte
  , datatypeChar
  , datatypeDouble
  , datatypeFloat
  , datatypeInt
  , datatypeLong
  , datatypeLongDouble
  , datatypeLongLongInt
  , datatypeShort
  , datatypeUnsigned
  , datatypeUnsignedChar
  , datatypeUnsignedLong
  , datatypeUnsignedShort
  , HasDatatype(..)
  , datatypeOf
  -- TODO: use a module for this namespace
  , opNull
  , opBand
  , opBor
  , opBxor
  , opLand
  , opLor
  , opLxor
  , opMax
  , opMaxloc
  , opMin
  , opMinloc
  , opProd
  , opSum
  , HasOp(..)
  , anySource
  , requestNull
  , statusIgnore
  , anyTag

  , abort
  , allgather
  , allreduce
  , alltoall
  , barrier
  , bcast
  , commCompare
  , commRank
  , commSize
  , exscan
  , finalize
  , finalized
  , gather
  , getCount
  , getLibraryVersion
  , getProcessorName
  , getVersion
  , iallgather
  , iallreduce
  , ialltoall
  , ibarrier
  , ibcast
  , iexscan
  , igather
  , init
  , initThread
  , initialized
  , iprobe
  , irecv
  , ireduce
  , iscan
  , iscatter
  , isend
  , probe
  , recv
  , reduce
  , scan
  , scatter
  , send
  , sendrecv
  , sendrecv'
  , test
  , wait
  , wait_
  ) where

import Prelude hiding (fromEnum, fst, init, toEnum)
import qualified Prelude

import Control.Monad (liftM)
import Data.Coerce
import Data.Ix
import qualified Data.Monoid as Monoid
import qualified Data.Semigroup as Semigroup
import Data.Version
import Foreign
import Foreign.C.String
import Foreign.C.Types
import GHC.Arr (indexError)
import System.IO.Unsafe (unsafePerformIO)

default (Int)

{#context prefix = "MPI"#}



--------------------------------------------------------------------------------

-- See GHC's includes/rts/Flags.h
foreign import ccall "&rts_argc" rtsArgc :: Ptr CInt
foreign import ccall "&rts_argv" rtsArgv :: Ptr (Ptr CString)
argc :: CInt
argv :: Ptr CString
argc = unsafePerformIO $ peek rtsArgc
argv = unsafePerformIO $ peek rtsArgv



--------------------------------------------------------------------------------

-- Arguments

fromEnum :: (Enum e, Integral i) => e -> i
fromEnum  = fromIntegral . Prelude.fromEnum

toEnum :: (Integral i, Enum e) => i -> e
toEnum  = Prelude.toEnum . fromIntegral

-- Return values

bool2maybe :: (Bool, a) -> Maybe a
bool2maybe (False, _) = Nothing
bool2maybe (True, x) = Just x

-- a Bool, probably represented as CInt
peekBool :: (Integral a, Storable a) => Ptr a -> IO Bool
peekBool  = liftM toBool . peek

-- a type that we wrapped, e.g. CInt and Rank
peekCoerce :: (Storable a, Coercible a b) => Ptr a -> IO b
peekCoerce = liftM coerce . peek

peekEnum :: (Integral i, Storable i, Enum e) => Ptr i -> IO e
peekEnum = liftM toEnum . peek

peekInt :: (Integral i, Storable i) => Ptr i -> IO Int
peekInt = liftM fromIntegral . peek



--------------------------------------------------------------------------------

{#pointer *MPI_Comm as Comm foreign newtype#}

deriving instance Eq Comm
deriving instance Ord Comm
deriving instance Show Comm



{#enum ComparisonResult {underscoreToCase} deriving (Eq, Ord, Read, Show)#}



newtype Count = Count CInt
  deriving (Eq, Ord, Enum, Integral, Num, Real, Storable)

instance Read Count where
  readsPrec p = map (\(c, s) -> (Count c, s)) . readsPrec p

instance Show Count where
  showsPrec p (Count c) = showsPrec p c

toCount :: Enum e => e -> Count
toCount e = Count (fromIntegral (fromEnum e))

fromCount :: Enum e => Count -> e
fromCount (Count c) = toEnum (fromIntegral c)



{#pointer *MPI_Datatype as Datatype foreign newtype#}

deriving instance Eq Datatype
deriving instance Ord Datatype
deriving instance Show Datatype



{#pointer *MPI_Op as Op foreign newtype#}

deriving instance Eq Op
deriving instance Ord Op
deriving instance Show Op



newtype Rank = Rank CInt
  deriving (Eq, Ord, Enum, Integral, Num, Real, Storable)

instance Read Rank where
  readsPrec p = map (\(r, s) -> (Rank r, s)) . readsPrec p

instance Show Rank where
  showsPrec p (Rank r) = showsPrec p r

instance Ix Rank where
  range (Rank rmin, Rank rmax) = Rank <$> [rmin..rmax]
  {-# INLINE index #-}
  index b@(Rank rmin, _) i@(Rank r)
    | inRange b i = fromIntegral (r - rmin)
    | otherwise   = indexError b i "MPI.Rank"
  inRange (Rank rmin, Rank rmax) (Rank r) = rmin <= r && r <= rmax

toRank :: Enum e => e -> Rank
toRank e = Rank (fromIntegral (fromEnum e))

fromRank :: Enum e => Rank -> e
fromRank (Rank r) = toEnum (fromIntegral r)

rootRank :: Rank
rootRank = toRank 0



{#pointer *MPI_Request as Request foreign newtype#}

deriving instance Eq Request
deriving instance Ord Request
deriving instance Show Request



{#pointer *MPI_Status as Status foreign newtype#}

deriving instance Eq Status
deriving instance Ord Status
deriving instance Show Status

-- statusError :: Status -> IO Error
-- statusError (Status mst) =
--   Error $ {#get MPI_Status.MPI_ERROR#} mst

getSource :: Status -> IO Rank
getSource (Status fst) =
  withForeignPtr fst (\pst -> Rank <$> {#get MPI_Status->MPI_SOURCE#} pst)

getTag :: Status -> IO Tag
getTag (Status fst) =
  withForeignPtr fst (\pst -> Tag <$> {#get MPI_Status->MPI_TAG#} pst)



newtype Tag = Tag CInt
  deriving (Eq, Ord, Read, Show, Num, Storable)

toTag :: Enum e => e -> Tag
toTag e = Tag (fromIntegral (fromEnum e))

fromTag :: Enum e => Tag -> e
fromTag (Tag t) = toEnum (fromIntegral t)

unitTag :: Tag
unitTag = toTag ()



{#enum ThreadSupport {underscoreToCase} deriving (Eq, Ord, Read, Show)#}



--------------------------------------------------------------------------------

{#fun pure mpihs_get_comm_null as commNull {+} -> `Comm'#}
{#fun pure mpihs_get_comm_self as commSelf {+} -> `Comm'#}
{#fun pure mpihs_get_comm_world as commWorld {+} -> `Comm'#}



{#fun pure mpihs_get_datatype_null as datatypeNull {+} -> `Datatype'#}

{#fun pure mpihs_get_byte as datatypeByte {+} -> `Datatype'#}
{#fun pure mpihs_get_char as datatypeChar {+} -> `Datatype'#}
{#fun pure mpihs_get_double as datatypeDouble {+} -> `Datatype'#}
{#fun pure mpihs_get_float as datatypeFloat {+} -> `Datatype'#}
{#fun pure mpihs_get_int as datatypeInt {+} -> `Datatype'#}
{#fun pure mpihs_get_long as datatypeLong {+} -> `Datatype'#}
{#fun pure mpihs_get_long_double as datatypeLongDouble {+} -> `Datatype'#}
{#fun pure mpihs_get_long_long_int as datatypeLongLongInt {+} -> `Datatype'#}
{#fun pure mpihs_get_short as datatypeShort {+} -> `Datatype'#}
{#fun pure mpihs_get_unsigned as datatypeUnsigned {+} -> `Datatype'#}
{#fun pure mpihs_get_unsigned_char as datatypeUnsignedChar {+} -> `Datatype'#}
{#fun pure mpihs_get_unsigned_long as datatypeUnsignedLong {+} -> `Datatype'#}
{#fun pure mpihs_get_unsigned_short as datatypeUnsignedShort {+} -> `Datatype'#}

class HasDatatype a where datatype :: Datatype
instance HasDatatype CChar where datatype = datatypeChar
instance HasDatatype CDouble where datatype = datatypeDouble
instance HasDatatype CFloat where datatype = datatypeFloat
instance HasDatatype CInt where datatype = datatypeInt
instance HasDatatype CLLong where datatype = datatypeLongLongInt
instance HasDatatype CLong where datatype = datatypeLong
instance HasDatatype CShort where datatype = datatypeShort
instance HasDatatype CUChar where datatype = datatypeUnsignedChar
instance HasDatatype CUInt where datatype = datatypeUnsigned
instance HasDatatype CULong where datatype = datatypeUnsignedLong
instance HasDatatype CUShort where datatype = datatypeUnsignedShort

-- instance Coercible Int CChar => HasDatatype Int where
--   datatype = datatype @CChar
-- instance Coercible Int CShort => HasDatatype Int where
--   datatype = datatype @CShort
-- instance Coercible Int CInt => HasDatatype Int where
--   datatype = datatype @CInt
-- instance Coercible Int CLong => HasDatatype Int where
--   datatype = datatype @CLong
-- instance Coercible Int CLLong => HasDatatype Int where
--   datatype = datatype @CLLong

-- instance HasDatatype Int where
--   datatype = if | coercible @Int @CChar -> datatype @CChar
--                 | coercible @Int @CShort -> datatype @CShort
--                 | coercible @Int @CInt -> datatype @CInt
--                 | coercible @Int @CLong -> datatype @CLong
--                 | coercible @Int @CLLong -> datatype @CLLong
-- instance HasDatatype Int8 where
--   datatype = if | coercible @Int @CChar -> datatype @CChar
--                 | coercible @Int @CShort -> datatype @CShort
--                 | coercible @Int @CInt -> datatype @CInt
--                 | coercible @Int @CLong -> datatype @CLong
--                 | coercible @Int @CLLong -> datatype @CLLong
-- instance HasDatatype Int16 where
--   datatype = if | coercible @Int @CChar -> datatype @CChar
--                 | coercible @Int @CShort -> datatype @CShort
--                 | coercible @Int @CInt -> datatype @CInt
--                 | coercible @Int @CLong -> datatype @CLong
--                 | coercible @Int @CLLong -> datatype @CLLong
-- instance HasDatatype Int32 where
--   datatype = if | coercible @Int @CChar -> datatype @CChar
--                 | coercible @Int @CShort -> datatype @CShort
--                 | coercible @Int @CInt -> datatype @CInt
--                 | coercible @Int @CLong -> datatype @CLong
--                 | coercible @Int @CLLong -> datatype @CLLong
-- instance HasDatatype Int64 where
--   datatype = if | coercible @Int @CChar -> datatype @CChar
--                 | coercible @Int @CShort -> datatype @CShort
--                 | coercible @Int @CInt -> datatype @CInt
--                 | coercible @Int @CLong -> datatype @CLong
--                 | coercible @Int @CLLong -> datatype @CLLong
-- instance HasDatatype Word where
--   datatype = if | coercible @Int @CUChar -> datatype @CUChar
--                 | coercible @Int @CUShort -> datatype @CUShort
--                 | coercible @Int @CUInt -> datatype @CUInt
--                 | coercible @Int @CULong -> datatype @CULong
--                 -- | coercible @Int @CULLong -> datatype @CULLong
-- instance HasDatatype Word8 where
--   datatype = if | coercible @Int @CUChar -> datatype @CUChar
--                 | coercible @Int @CUShort -> datatype @CUShort
--                 | coercible @Int @CUInt -> datatype @CUInt
--                 | coercible @Int @CULong -> datatype @CULong
--                 -- | coercible @Int @CULLong -> datatype @CULLong
-- instance HasDatatype Word16 where
--   datatype = if | coercible @Int @CUChar -> datatype @CUChar
--                 | coercible @Int @CUShort -> datatype @CUShort
--                 | coercible @Int @CUInt -> datatype @CUInt
--                 | coercible @Int @CULong -> datatype @CULong
--                 -- | coercible @Int @CULLong -> datatype @CULLong
-- instance HasDatatype Word32 where
--   datatype = if | coercible @Int @CUChar -> datatype @CUChar
--                 | coercible @Int @CUShort -> datatype @CUShort
--                 | coercible @Int @CUInt -> datatype @CUInt
--                 | coercible @Int @CULong -> datatype @CULong
--                 -- | coercible @Int @CULLong -> datatype @CULLong
-- instance HasDatatype Word64 where
--   datatype = if | coercible @Int @CUChar -> datatype @CUChar
--                 | coercible @Int @CUShort -> datatype @CUShort
--                 | coercible @Int @CUInt -> datatype @CUInt
--                 | coercible @Int @CULong -> datatype @CULong
--                 -- | coercible @Int @CULLong -> datatype @CULLong
-- instance HasDatatype Float where
--   datatype = if | coercible @Float @CFloat -> datatype @CFloat
--                 | coercible @Float @CDouble -> datatype @CDouble
-- instance HasDatatype Double where
--   datatype = if | coercible @Double @CFloat -> datatype @CFloat
--                 | coercible @Double @CDouble -> datatype @CDouble

datatypeOf :: forall a p. HasDatatype a => p a -> Datatype
datatypeOf _ = datatype @a



{#fun pure mpihs_get_op_null as opNull {+} -> `Op'#}

{#fun pure mpihs_get_band as opBand {+} -> `Op'#}
{#fun pure mpihs_get_bor as opBor {+} -> `Op'#}
{#fun pure mpihs_get_bxor as opBxor {+} -> `Op'#}
{#fun pure mpihs_get_land as opLand {+} -> `Op'#}
{#fun pure mpihs_get_lor as opLor {+} -> `Op'#}
{#fun pure mpihs_get_lxor as opLxor {+} -> `Op'#}
{#fun pure mpihs_get_max as opMax {+} -> `Op'#}
{#fun pure mpihs_get_maxloc as opMaxloc {+} -> `Op'#}
{#fun pure mpihs_get_min as opMin {+} -> `Op'#}
{#fun pure mpihs_get_minloc as opMinloc {+} -> `Op'#}
{#fun pure mpihs_get_prod as opProd {+} -> `Op'#}
{#fun pure mpihs_get_sum as opSum {+} -> `Op'#}

instance HasDatatype a => HasDatatype (Monoid.Product a) where
  datatype = datatype @a
instance HasDatatype a => HasDatatype (Monoid.Sum a) where
  datatype = datatype @a
instance HasDatatype a => HasDatatype (Semigroup.Max a) where
  datatype = datatype @a
instance HasDatatype a => HasDatatype (Semigroup.Min a) where
  datatype = datatype @a

class (Monoid a, HasDatatype a) => HasOp a where op :: Op
instance (Num a, HasDatatype a) => HasOp (Monoid.Product a) where
  op = opProd
instance (Num a, HasDatatype a) => HasOp (Monoid.Sum a) where
  op = opSum
instance (Bounded a, Ord a, HasDatatype a) => HasOp (Semigroup.Max a) where
  op = opMax
instance (Bounded a, Ord a, HasDatatype a) => HasOp (Semigroup.Min a) where
  op = opMin



{#fun pure mpihs_get_any_source as anySource {} -> `Rank' toRank#}



{#fun pure mpihs_get_request_null as requestNull {+} -> `Request'#}



{#fun pure mpihs_get_status_ignore as statusIgnore {} -> `Status'#}

withStatusIgnore :: (Ptr Status -> IO ()) -> IO ()
withStatusIgnore = withStatus statusIgnore



{#fun pure mpihs_get_any_tag as anyTag {} -> `Tag' toTag#}



--------------------------------------------------------------------------------

{#fun Abort as ^
    { withComm* %`Comm'
    , fromIntegral `Int'
    } -> `()' return*-#}

{#fun Allgather as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun Allreduce as ^
    { id `Ptr ()'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withOp* %`Op'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun Alltoall as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun Barrier as ^ {withComm* %`Comm'} -> `()' return*-#}

{#fun Bcast as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun unsafe Comm_compare as ^
    { withComm* %`Comm'
    , withComm* %`Comm'
    , alloca- `ComparisonResult' peekEnum*
    } -> `()' return*-#}

{#fun unsafe Comm_rank as ^
    { withComm* %`Comm'
    , alloca- `Rank' peekCoerce*
    } -> `()' return*-#}

{#fun unsafe Comm_size as ^
    { withComm* %`Comm'
    , alloca- `Rank' peekCoerce*
    } -> `()' return*-#}

{#fun Exscan as ^
    { id `Ptr ()'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withOp* %`Op'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun Finalize as ^ {} -> `()' return*-#}

{#fun Finalized as ^ {alloca- `Bool' peekBool*} -> `()' return*-#}

{#fun Gather as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun unsafe Get_count as ^
    { withStatus* `Status'
    , withDatatype* %`Datatype'
    , alloca- `Int' peekInt*
    } -> `()' return*-#}

{#fun unsafe Get_library_version as getLibraryVersion_
    { id `CString'
    , alloca- `Int' peekInt*
    } -> `()' return*-#}

getLibraryVersion :: IO String
getLibraryVersion =
  do buf <- mallocForeignPtrBytes {#const MPI_MAX_LIBRARY_VERSION_STRING#}
     withForeignPtr buf $ \ptr ->
       do len <- getLibraryVersion_ ptr
          str <- peekCStringLen (ptr, len)
          return str

{#fun unsafe Get_processor_name as getProcessorName_
    { id `CString'
    , alloca- `Int' peekInt*
    } -> `()' return*-#}

getProcessorName :: IO String
getProcessorName =
  do buf <- mallocForeignPtrBytes {#const MPI_MAX_PROCESSOR_NAME#}
     withForeignPtr buf $ \ptr ->
       do len <- getProcessorName_ ptr
          str <- peekCStringLen (ptr, len)
          return str

{#fun unsafe Get_version as getVersion_
    { alloca- `Int' peekInt*
    , alloca- `Int' peekInt*
    } -> `()' return*-#}

getVersion :: IO Version
getVersion =
  do (major, minor) <- getVersion_
     return (makeVersion [major, minor])

{#fun Iallgather as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Iallreduce as ^
    { id `Ptr ()'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withOp* %`Op'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Ialltoall as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Ibarrier as ^
    { withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Ibcast as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Iexscan as ^
    { id `Ptr ()'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withOp* %`Op'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Igather as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun unsafe Initialized as ^ {alloca- `Bool' peekBool*} -> `()' return*-#}

{#fun Init as init_
    { with* `CInt'
    , with* `Ptr CString'
    } -> `()' return*-#}

init :: IO ()
init = init_ argc argv

{#fun Init_thread as initThread_
    { with* `CInt'
    , with* `Ptr CString'
    , fromEnum `ThreadSupport'
    , alloca- `ThreadSupport' peekEnum*
    } -> `()' return*-#}

initThread :: ThreadSupport -> IO ThreadSupport
initThread ts = initThread_ argc argv ts

iprobeBool :: Rank -> Tag -> Comm -> IO (Bool, Status)
iprobeBool rank tag comm =
  withComm comm $ \comm' ->
  do st <- Status <$> mallocForeignPtrBytes {#sizeof MPI_Status#}
     withStatus st $ \st' ->
       do alloca $ \flag ->
            do _ <- {#call mpihs_iprobe as iprobeBool_#}
                    (fromRank rank) (fromTag tag) comm' flag st'
               b <- peekBool flag
               return (b, st)

iprobe :: Rank -> Tag -> Comm -> IO (Maybe Status)
iprobe rank tag comm = bool2maybe <$> iprobeBool rank tag comm

{#fun Irecv as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , fromTag `Tag'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Ireduce as ^
    { id `Ptr ()'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withOp* %`Op'
    , fromRank `Rank'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Iscan as ^
    { id `Ptr ()'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withOp* %`Op'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Iscatter as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Isend as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , fromTag `Tag'
    , withComm* %`Comm'
    , +
    } -> `Request' return*#}

{#fun Probe as ^
    { fromRank `Rank'
    , fromTag `Tag'
    , withComm* %`Comm'
    , +
    } -> `Status' return*#}

{#fun Recv as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , fromTag `Tag'
    , withComm* %`Comm'
    , +
    } -> `Status' return*#}

{#fun Reduce as ^
    { id `Ptr ()'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withOp* %`Op'
    , fromRank `Rank'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun Scan as ^
    { id `Ptr ()'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , withOp* %`Op'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun Scatter as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun Send as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , fromTag `Tag'
    , withComm* %`Comm'
    } -> `()' return*-#}

{#fun Sendrecv as ^
    { id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , fromTag `Tag'
    , id `Ptr ()'
    , fromCount `Count'
    , withDatatype* %`Datatype'
    , fromRank `Rank'
    , fromTag `Tag'
    , withComm* %`Comm'
    , +
    } -> `Status' return*#}

-- TODO: use these as default
sendrecv' :: forall a b. (HasDatatype a, HasDatatype b) =>
             Ptr a -> Count -> Rank -> Tag ->
             Ptr b -> Count -> Rank -> Tag ->
             Comm -> IO Status
sendrecv' sendbuf sendcount sendrank sendtag
          recvbuf recvcount recvrank recvtag
          comm =
  sendrecv (castPtr sendbuf) sendcount (datatype @a) sendrank sendtag
           (castPtr recvbuf) recvcount (datatype @b) recvrank recvtag
           comm

testBool :: Request -> IO (Bool, Status)
testBool req =
  withRequest req $ \req' ->
  alloca $ \flag ->
  do st <- Status <$> mallocForeignPtrBytes {#sizeof MPI_Status#}
     withStatus st $ \st' ->
       do _ <- {#call Test as testBool_#} req' flag st'
          b <- peekBool flag
          return (b, st)

test :: Request -> IO (Maybe Status)
test req = bool2maybe <$> testBool req

{#fun Wait as ^
    { withRequest* `Request'
    , +
    } -> `Status' return*#}

{#fun Wait as wait_
    { withRequest* `Request'
    , withStatusIgnore- `Status'
    } -> `()' return*-#}
