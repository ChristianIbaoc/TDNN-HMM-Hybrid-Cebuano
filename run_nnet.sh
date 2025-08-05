. ./cmd.sh
. ./path.sh
dir=exp/chain/tdnn7r_sp

gunzip $dir/decode_test_sw1_tg/lat.1.gz

src/latbin/lattice-1best --acoustic-scale=0.1 ark:$dir/decode_test_sw1_tg/lat.1 ark:out/1best.lats

src/latbin/nbest-to-linear ark:out/1best.lats ark:out/1best.ali 'ark,t:|int2sym.pl -f 2- words.txt > out/text'

src/bin/ali-to-phones --ctm-output exp/chain/tdnn7r_sp/final.mdl ark:out/1best.ali out/1best.ctm

utils/inttoPhoneme.sh out/1best.ctm exp/chain/tdnn7r_sp/phones.txt out/finalPhonemeList.txt
