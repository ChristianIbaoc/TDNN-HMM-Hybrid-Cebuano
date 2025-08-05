#!/bin/bash
. ./path.sh || exit 1
. ./cmd.sh || exit 1
nj=8       # number of parallel jobs - 1 is perfect for such a small dataset
lm_order=2 # language model order (n-gram quantity) - 1 is enough for digits grammar
stage=-6
isolate=false
skip=true
dataset=trainaug

# Safety mechanism (possible running this script with modified arguments)
. utils/parse_options.sh || exit 1
[[ $# -ge 1 ]] && { echo "Wrong arguments!"; exit 1; }
if [ $stage -le -6 ]; then
	# Removing previously created data (from last run.sh execution)
	rm -rf exp mfcc mfcc_hires mfcc_perturbed data/train/spk2utt data/train/cmvn.scp data/train/feats.scp data/train/split1 data/test/spk2utt data/test/cmvn.scp data/test/feats.scp data/test/split1 data/local/lang data/lang data/local/tmp data/local/dict/lexiconp.txt data/ones data/test_hires data/train_hires data/train_sp_hires data/train_sp_max2_hires data/trainaug data/lang_test
	echo
	echo "===== PREPARING ACOUSTIC DATA ====="
	echo
	# Needs to be prepared by hand (or using self written scripts):
	#
	# spk2gender  [<speaker-id> <gender>]
	# wav.scp     [<uterranceID> <full_path_to_audio_file>]
	# text        [<uterranceID> <text_transcription>]
	# utt2spk     [<uterranceID> <speakerID>]
	# corpus.txt  [<text_transcription>]
	# Making spk2utt files
	utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
	utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt
	echo
	echo "===== FEATURES EXTRACTION ====="
	echo
	# Making feats.scp files
	mfccdir=mfcc
	# Uncomment and modify arguments in scripts below if you have any problems with data sorting
	utils/validate_data_dir.sh data/train     # script for checking prepared data - here: for data/train directory
	utils/fix_data_dir.sh data/train          # tool for data proper sorting if needed - here: for data/train directory
	utils/fix_data_dir.sh data/test
	steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir
	steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/test exp/make_mfcc/test $mfccdir
	# Making cmvn.scp files
	steps/compute_cmvn_stats.sh data/train exp/make_mfcc/train $mfccdir
	steps/compute_cmvn_stats.sh data/test exp/make_mfcc/test $mfccdir
	
	utils/data/perturb_data_dir_speed_3way.sh --always-include-prefix true data/train data/trainaug
	
	utils/fix_data_dir.sh data/trainaug
	steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/trainaug exp/make_mfcc/trainaug $mfccdir
	steps/compute_cmvn_stats.sh data/trainaug exp/make_mfcc/trainaug $mfccdir
	echo
	echo "===== PREPARING LANGUAGE DATA ====="
	echo
	# Needs to be prepared by hand (or using self written scripts):
	#
	# lexicon.txt           [<word> <phone 1> <phone caref2> ...]
	# nonsilence_phones.txt [<phone>]
	# silence_phones.txt    [<phone>]
	# optional_silence.txt  [<phone>]
	# Preparing language data
	utils/prepare_lang.sh --position-dependent-phones true --share-silence-phones false --sil-prob 0.5 data/local/dict "<UNK>" data/local/lang data/lang
	echo
	echo "===== LANGUAGE MODEL CREATION ====="
	echo "===== MAKING lm.arpa ====="
	echo
	loc=`which ngram-count`;
	if [ -z $loc ]; then
		if uname -a | grep 64 >/dev/null; then
		        sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
		else
		                sdir=$KALDI_ROOT/tools/srilm/bin/i686
		fi
		if [ -f $sdir/ngram-count ]; then
		                echo "Using SRILM language modelling tool from $sdir"
		                export PATH=$PATH:$sdir
		else
		                echo "SRILM toolkit is probably not installed.
		                        Instructions: tools/install_srilm.sh"
		                exit 1
		fi
	fi
	local=data/local
	mkdir $local/tmp
	ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt \
	-wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa
	utils/format_lm.sh data/lang data/local/lm/arpa data/local/dict/lexicon.txt data/lang_test
	echo
	echo "===== MAKING G.fst ====="
	echo
	lang=data/lang_test
	arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang/words.txt $local/tmp/lm.arpa $lang/G.fst
	
	if [ "$isolate" = "true" ]; then
		exit 1
	fi
fi
if [ $stage -le -5 ]; then
	rm -rf exp/mono
	echo
	echo "===== MONO TRAINING ====="
	echo
	steps/train_mono.sh --nj $nj --cmd "$train_cmd" data/$dataset data/lang_test exp/mono  || exit 1
	echo
	echo "===== MONO ALIGNMENT ====="
	echo
	steps/align_si.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" data/$dataset data/lang_test exp/mono exp/mono_ali || exit 1
	echo
	echo "===== MONO DECODING ====="
	echo
	utils/mkgraph.sh --transition-scale 1.0 data/lang_test exp/mono exp/mono/graph || exit 1
	steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/mono/graph data/test exp/mono/decode
	utils/bestWER.sh
	if [ "$isolate" = "true" ]; then
		exit 1
	fi
fi
if [ $stage -le -4 ]; then
	rm -rf exp/tri1
	echo
	echo "===== TRI1 (first triphone pass) TRAINING ====="
	echo
	steps/train_deltas.sh --cmd "$train_cmd" 3000 11000 data/$dataset data/lang_test exp/mono_ali exp/tri1 || exit 1
	echo
	echo "===== TRI1 (first triphone pass) DECODING ====="
	echo
	utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph || exit 1
	steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/tri1/graph data/test exp/tri1/decode
	echo
	echo "===== TRI1 (first triphone pass) ALIGNING ====="
	echo
	steps/align_si.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" data/$dataset data/lang_test exp/tri1 exp/tri1_ali || exit 1
	utils/bestWER.sh
	if [ "$isolate" = "true" ]; then
		exit 1
	fi
fi
if [ $stage -le -3 ]; then
	rm -rf exp/tri2
	echo
	echo "===== TRAIN LDA+MLLT (second triphone pass) ALIGNING ====="
	echo
	steps/train_lda_mllt.sh --cmd "$train_cmd" 3500 11000 data/$dataset data/lang_test exp/tri1 exp/tri2
	utils/mkgraph.sh data/lang_test exp/tri2 exp/tri2/graph || exit 1
	echo
	echo "===== TRAIN LDA+MLLT (second triphone pass) DECODING ====="
	echo
	steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/tri2/graph data/test exp/tri2/decode
	echo
	echo "===== TRAIN LDA+MLLT (second triphone pass) ALIGNMENT ====="
	echo
	steps/align_fmllr.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" data/$dataset data/lang_test exp/tri2 exp/tri2_ali
	utils/bestWER.sh
	if [ "$isolate" = "true" ]; then
		exit 1
	fi
fi
if [ $stage -le -2 ]; then
	rm -rf exp/tri3
	echo
	echo "===== TRAIN LDA+MLLT+SAT (third triphone pass) TRAINING ====="
	echo
	steps/train_sat.sh --cmd "$train_cmd" 4000 13000 data/$dataset data/lang_test exp/tri2_ali exp/tri3
	$train_cmd exp/tri3/graph_sw1_tg/mkgraph.log utils/mkgraph.sh data/lang_test exp/tri3 exp/tri3/graph_sw1_tg

	echo
	echo "===== TRAIN LDA+MLLT (third triphone pass) DECODING ====="
	echo
	steps/decode_fmllr.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/tri3/graph_sw1_tg data/test exp/tri3/decode
	utils/bestWER.sh
	echo
	echo "===== Third Triphone Alignment and MMI Training ====="
	echo
	steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" data/$dataset data/lang_test exp/tri3 exp/tri3_ali
	utils/bestWER.sh
	if [ "$isolate" = "true" ]; then
		exit 1
	fi
fi
if [ "$skip" = "false" ]; then
	steps/make_denlats.sh --nj $nj --cmd "$decode_cmd" --config conf/decode.config  --transform-dir exp/tri3_ali data/train data/lang exp/tri3 exp/tri3_denlats
	echo
	echo "===== Third Triphone Alignment and MMI DECODING ====="
	echo
	numOfIterations=4
	steps/train_mmi.sh --cmd "$decode_cmd" --boost 0.1 --num-iters $numOfIterations data/train data/lang exp/tri3_{ali,denlats} exp/tri3_mm0.1
	for iter in 1 2 3 4; do
		(
			graph_dir=exp/tri3/graph_sw1_tg
			decode_dir=exp/tri3_mm0.1/decode_eval_${iter}.mdl_sw1_tg
			steps/decode.sh --nj $nj --cmd "$decode_cmd" --config conf/decode.config --iter $iter --transform-dir exp/tri3/decode $graph_dir data/test $decode_dir
		) & done
	utils/bestWER.sh
	echo
	echo "===== Third Triphone Alignment and FMMI+MMI TRAINING ====="
	echo
	steps/train_diag_ubm.sh --silence-weight 0.5 --nj $nj --cmd "$train_cmd" 300 data/train data/lang exp/tri3_ali exp/tri3_dubm
	steps/train_mmi_fmmi.sh --learning-rate 0.0025 --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3_ali exp/tri3_dubm exp/tri3_denlats exp/tri3_fmmi_b0.1

	echo
	echo "===== Third Triphone Alignment and FMMI+MMI DECODING ====="command to finish
	echo

	for iter in 1 2 3 4; do 
		(
			graph_dir=exp/tri3/graph_sw1_tg
			decode_dir=exp/tri3_fmmi_b0.1/decode_eval_it${iter}_sw1_tg
			steps/decode_fmmi.sh --nj $nj --cmd "$decode_cmd" --iter $iter --transform-dir exp/tri3/decode --config conf/decode.config $graph_dir data/test $decode_dir
		) & done


	#repeat?
	#steps/decode.sh --nj $nj  --cmd "$decode_cmd" --config conf/decode.config --transform-dir exp/tri3
	utils/bestWER.sh 1
fi

if [ $stage -le -1 ]; then
	rm -rf data/${dataset}_sp data/${dataset}_sp_hires
	echo
	echo "===== run.sh script is finished ====="
	echo
	echo
	echo "===== run_tdnn_2o.sh script is starting ====="
	echo
	local/chain/run_tdnn.sh --nj $nj --stride 3 --fpi 3000000 --exp_dir exp/tri3
	echo
	echo "===== run_tdnn_2o.sh script is finished ====="
	echo
	utils/bestWER.sh
fi
