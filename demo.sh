#!/usr/bin/env bash

DIR=exp/chain/tdnn1_sp
DIR2=exp/chain/tdnn1_sp_online
word=$1

rm -rf demoaug
#ASSUMPTION, FLOWING PIPELINE RECORDING. FOR NOW, MANUAL
mv demo/demo.py ./
rm -rf demo
mkdir demo
mv demo.py demo

cd demo
python demo.py $word

#AFTER RECORDING
cd ../
utils/fix_data_dir.sh demo 
utils/validate_data_dir.sh demo
python finalize.py demo/text data/local/dict/referenceW2Syll.txt text
cp text demo

utils/data/perturb_data_dir_speed_3way.sh --always-include-prefix true demo demoaug
utils/fix_data_dir.sh demoaug
utils/validate_data_dir.sh demoaug
#END DATA CONFIRMATION

#START DATA-ING MUAHHAH
mfccdir=mfcc_demo
steps/make_mfcc.sh --cmd run.pl --nj 1 --mfcc-config conf/mfcc_hires.conf demoaug exp/make_hires/demoaug $mfccdir;
steps/compute_cmvn_stats.sh demoaug exp/make_hires/demoaug $mfccdir;
utils/fix_data_dir.sh demoaug  # remove segments with problems;

#NORMAL DECODING
steps/online/nnet2/extract_ivectors_online.sh --cmd run.pl --nj 1 demoaug exp/nnet3/extractor exp/nnet3/ivectors_demoaug || exit 1;
steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
          --nj 1 --cmd run.pl \
          --online-ivector-dir exp/nnet3/ivectors_demoaug \
          $DIR/graph_sw1_tg demoaug \
          $DIR/decode_demoaug || exit 1;
          
          
        
#ONLINE DECODING???
steps/online/nnet3/prepare_online_decoding.sh \
       --mfcc-config conf/mfcc_hires.conf \
       data/ones exp/nnet3/extractor $DIR $DIR2
       
steps/online/nnet3/decode.sh --nj 1 --cmd run.pl \
          --acwt 1.0 --post-decode-acwt 10.0 \
         $DIR/graph_sw1_tg demoaug \
         $DIR2/decode_demoaug || exit 1;
         
         
#TRY IF WORKS:
steps/get_ctm.sh --use-segments true --frame_shift 0.019 demoaug data/lang_test exp/chain/tdnn1_sp/decode_demoaug
steps/get_ctm.sh --use-segments true --frame_shift 0.019 demoaug data/lang_test exp/chain/tdnn1_sp_online/decode_demoaug

utils/syllable-processor.py exp/chain/tdnn1_sp/decode_demoaug/score_1/demoaug.ctm data/local/dict/referenceW2Syll.txt
utils/syllable-processor.py exp/chain/tdnn1_sp_online/decode_demoaug/score_1/demoaug.ctm data/local/dict/referenceW2Syll.txt
utils/syllable-filter-final.py exp/chain/tdnn1_sp/decode_demoaug/score_1/Output.txt
utils/syllable-filter-final.py exp/chain/tdnn1_sp_online/decode_demoaug/score_1/Output.txt

utils/bestWER.sh
