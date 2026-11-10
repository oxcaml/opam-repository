#!/bin/sh
set -e

cd kernel/src

sed -e '3s/include/open/' \
    -e '4s|^$|# 5 "kernel/src/slice.ml"|' \
    -e '23s/value_or_null & bits64, //' \
    -e "24s/(v, v').*/v = read_write, v' = read]/" \
    -e '614,839d' \
    -e '840s|^$|# 841 "kernel/src/slice.ml"|' \
    -e '842s/read_write]/read_write read]/' \
    -e '855s/$/]]/' \
    -e '856,$d' \
    slice.ml > slice_make_ext0.ml

sed -e '3s/include/open/' \
    -e '4s|^$|# 5 "kernel/src/slice.ml"|' \
    -e '23s/value_or_null & bits64, //' \
    -e "24s/(v, v').*/v = immutable, v' = write]/" \
    -e '614,855d' \
    -e '856s|^$|# 857 "kernel/src/slice.ml"|' \
    -e '858s/immutable]/immutable write]/' \
    -e '871s/$/]]/' \
    -e '872,$d' \
    slice.ml > slice_make_ext_imm0.ml

sed -e '3s/include/open/' \
    -e '4s|^$|# 5 "kernel/src/slice.ml"|' \
    -e '23s/, bits64//' \
    -e "24s/(v, v').*/v = read_write, v' = read]/" \
    -e '614,896d' \
    -e '897s|^$|# 898 "kernel/src/slice.ml"|' \
    -e '899s/read_write]/read_write read]/' \
    -e '912s/$/]]/' \
    -e '913,$d' \
    slice.ml > slice_make_slice.ml

sed -e '3s/include/open/' \
    -e '4s|^$|# 5 "kernel/src/slice.ml"|' \
    -e '23s/, bits64//' \
    -e "24s/(v, v').*/v = immutable, v' = write]/" \
    -e '614,912d' \
    -e '913s|^$|# 914 "kernel/src/slice.ml"|' \
    -e '915s/immutable]/immutable write]/' \
    -e '928s/$/]]/' \
    -e '929,$d' \
    slice.ml > slice_make_slice_imm.ml

sed -e '3s/include/open/' \
    -e '22,613d' \
    -e '841,872d' \
    -e '874s/Slice_ext0/Slice_make_ext0.&/' \
    -e '878s/Slice_ext_imm0/Slice_make_ext_imm0.&/' \
    -e '898,929d' \
    -e '931s/(Slice)/(Slice_make_slice.Slice)/' \
    -e '942s/Slice_imm/Slice_make_slice_imm.&/' \
    -e '960s/$/]/' \
    -e '961,$d' \
    slice.ml > slice_make_generic_external_mut.ml

sed -e '21s/\[%%inline_functor/open Slice_make_generic_external_mut/' \
    -e '22,960d' \
    slice.ml > slice.ml.tmp
mv slice.ml.tmp slice.ml

cd ../../test/inlining-tests

sed -e '3s/^$/module Slice = Ox.Slice/' \
    -e '4,15d' \
    -e '33d' \
    -e '495s/end/]/' \
    -e '496,$d' \
    slice.ml > slice_ext.ml
echo 'include module type of Ox.Slice.Ext' > slice_ext.mli

sed -e '3s/^$/module Slice = Ox.Slice/' \
    -e '4,15d' \
    -e '33,697d' \
    -e '922s/end/]/' \
    -e '923,$d' \
    slice.ml > slice_imm.ml
echo 'include module type of Ox.Slice.Imm' > slice_imm.mli

sed -e '3s/^$/module Slice = Ox.Slice/' \
    -e '4,15d' \
    -e '33,976d' \
    -e '1496s/end/]/' \
    -e '1497,$d' \
    slice.ml > slice_isize_ext.ml
echo 'include module type of Ox.Slice.Isize.Ext' > slice_isize_ext.mli

sed -e '3s/^$/module Slice = Ox.Slice/' \
    -e '4,15d' \
    -e '33,1718d' \
    -e '1976s/end/]/' \
    -e '1977,$d' \
    slice.ml > slice_isize_imm.ml
echo 'include module type of Ox.Slice.Isize.Imm' > slice_isize_imm.mli

sed -e '3s/^$/module Slice = Ox.Slice/' \
    -e '4,15d' \
    -e '33,962d' \
    -e '976s/struct/Slice_isize_ext/' \
    -e '977,1496d' \
    -e '1718s/struct/Slice_isize_imm/' \
    -e '1719,1976d' \
    -e '2015s/end//' \
    slice.ml > slice_isize.ml
echo 'include module type of Ox.Slice.Isize' > slice_isize.mli

sed -e '33s/struct/Slice_ext/' \
    -e '34,495d' \
    -e '697s/struct/Slice_imm/' \
    -e '698,922d' \
    -e '962s/struct/Slice_isize]/' \
    -e '963,$d' \
    slice.ml > slice.ml.tmp
mv slice.ml.tmp slice.ml
