#!/usr/bin/env bash
dir=exp/tri2
n=8

for i in $(seq 1 $n)
do
	src/latbin/lattice-scale --acoustic-scale=0.1 ark:"gunzip -c $dir/decode/lat.${i}.gz|" ark:$dir/decode/scaled.lats
	src/latbin/lattice-to-nbest --n=10 ark:$dir/decode/scaled.lats ark:$dir/decode/ltnbest${i}.lats
	src/latbin/nbest-to-linear ark:$dir/decode/ltnbest${i}.lats ark,t:$dir/decode/${i}.ali "ark,t:|utils/int2sym.pl -f 2- $dir/graph/words.txt > $dir/decode/text${i}" "ark,t:$dir/decode/${i}.lm" "ark,t:$dir/decode/${i}.ac"

done
#IF YOU ADD LM and AC, LOWEST VALUE IS BEST ANSWER, NORMALIZE AND WE GET VALUES
