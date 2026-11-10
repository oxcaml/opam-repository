#!/bin/sh
set -e

cd kernel/src

{
  echo '# 1 "kernel/src/slice.ml"'
  sed -ne '1,2p' slice.ml
  echo 'open Slice_intf.Definitions'
  sed -ne '4,22p' slice.ml
  echo '  [@kind ptr_kind = (bits64)]'
  echo "  [@mode v = read_write, v' = read]"
  sed -ne '25,613p' slice.ml
  echo '# 841 "kernel/src/slice.ml"'
  sed -ne '841p' slice.ml
  echo '  Make [@kind bits64] [@mode read_write read]'
  sed -ne '843,855p' slice.ml
  echo ']]'
} > slice_make_ext0.ml

{
  echo '# 1 "kernel/src/slice.ml"'
  sed -ne '1,2p' slice.ml
  echo 'open Slice_intf.Definitions'
  sed -ne '4,22p' slice.ml
  echo '  [@kind ptr_kind = (bits64)]'
  echo "  [@mode v = immutable, v' = write]"
  sed -ne '25,613p' slice.ml
  echo '# 857 "kernel/src/slice.ml"'
  sed -ne '857p' slice.ml
  echo '  Make [@kind bits64] [@mode immutable write]'
  sed -ne '859,871p' slice.ml
  echo ']]'
} > slice_make_ext_imm0.ml

{
  echo '# 1 "kernel/src/slice.ml"'
  sed -ne '1,2p' slice.ml
  echo 'open Slice_intf.Definitions'
  sed -ne '4,22p' slice.ml
  echo '  [@kind ptr_kind = (value_or_null & bits64)]'
  echo "  [@mode v = read_write, v' = read]"
  sed -ne '25,613p' slice.ml
  echo '# 898 "kernel/src/slice.ml"'
  sed -ne '898p' slice.ml
  echo '  Make [@kind value_or_null & bits64] [@mode read_write read]'
  sed -ne '900,912p' slice.ml
  echo ']]'
} > slice_make_slice.ml

{
  echo '# 1 "kernel/src/slice.ml"'
  sed -ne '1,2p' slice.ml
  echo 'open Slice_intf.Definitions'
  sed -ne '4,22p' slice.ml
  echo '  [@kind ptr_kind = (value_or_null & bits64)]'
  echo "  [@mode v = immutable, v' = write]"
  sed -ne '25,613p' slice.ml
  echo '# 914 "kernel/src/slice.ml"'
  sed -ne '914p' slice.ml
  echo '  Make [@kind value_or_null & bits64] [@mode immutable write]'
  sed -ne '916,928p' slice.ml
  echo ']]'
} > slice_make_slice_imm.ml

{
  sed -ne '1,2p' slice.ml
  echo 'open Slice_intf.Definitions'
  sed -ne '4,20p' slice.ml
  echo 'module Slice_ext0 = Slice_make_ext0.Slice_ext0'
  echo 'module Slice_ext_imm0 = Slice_make_ext_imm0.Slice_ext_imm0'
  echo 'module Slice = Slice_make_slice.Slice'
  echo 'module Slice_imm = Slice_make_slice_imm.Slice_imm'
  echo
  sed -ne '21p' slice.ml
  sed -ne '614,840p' slice.ml
  sed -ne '873,897p' slice.ml
  sed -ne '930,960p' slice.ml
  echo ']'
} > slice_make_generic_external_mut.ml

{
  sed -ne '1,20p' slice.ml
  echo 'module Slice_ext = Slice_make_generic_external_mut.Slice_ext'
  echo 'module Slice_ext_imm = Slice_make_generic_external_mut.Slice_ext_imm'
  echo 'module Slice_ext_mut = Slice_make_generic_external_mut.Slice_ext_mut'
  echo 'module Slice_generic = Slice_make_generic_external_mut.Slice_generic'
  echo 'module Slice_generic_imm = Slice_make_generic_external_mut.Slice_generic_imm'
  echo 'module Slice_mut = Slice_make_generic_external_mut.Slice_mut'
  sed -ne '961,$p' slice.ml
} > slice.ml.tmp
mv slice.ml.tmp slice.ml

cd ../../test/inlining-tests

{
  sed -ne '1,2p' slice.ml
  echo 'module Slice = Ox.Slice'
  sed -ne '16,32p' slice.ml
  sed -ne '34,494p' slice.ml
  echo ']'
} > slice_ext.ml
echo 'include module type of Ox.Slice.Ext' > slice_ext.mli

{
  sed -ne '1,2p' slice.ml
  echo 'module Slice = Ox.Slice'
  sed -ne '16,32p' slice.ml
  sed -ne '698,921p' slice.ml
  echo ']'
} > slice_imm.ml
echo 'include module type of Ox.Slice.Imm' > slice_imm.mli

{
  sed -ne '1,2p' slice.ml
  echo 'module Slice = Ox.Slice'
  sed -ne '16,32p' slice.ml
  sed -ne '977,1495p' slice.ml
  echo ']'
} > slice_isize_ext.ml
echo 'include module type of Ox.Slice.Isize.Ext' > slice_isize_ext.mli

{
  sed -ne '1,2p' slice.ml
  echo 'module Slice = Ox.Slice'
  sed -ne '16,32p' slice.ml
  sed -ne '1719,1975p' slice.ml
  echo ']'
} > slice_isize_imm.ml
echo 'include module type of Ox.Slice.Isize.Imm' > slice_isize_imm.mli

{
  sed -ne '1,2p' slice.ml
  echo 'module Slice = Ox.Slice'
  sed -ne '16,32p' slice.ml
  sed -ne '963,975p' slice.ml
  echo '  module Ext = Slice_isize_ext'
  sed -ne '1497,1717p' slice.ml
  echo '  module Imm = Slice_isize_imm'
  sed -ne '1977,2014p' slice.ml
  echo ']'
} > slice_isize.ml
echo 'include module type of Ox.Slice.Isize' > slice_isize.mli

{
  sed -ne '1,32p' slice.ml
  echo 'module Ext = Slice_ext'
  sed -ne '496,696p' slice.ml
  echo 'module Imm = Slice_imm'
  sed -ne '923,961p' slice.ml
  echo 'module Isize = Slice_isize]'
} > slice.ml.tmp
mv slice.ml.tmp slice.ml
