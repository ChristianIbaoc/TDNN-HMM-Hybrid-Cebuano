# Defining Kaldi root directory
export KALDI_ROOT=/mnt/KINGSTON/Kaldi/kaldi
# Setting paths to useful tools
export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:/mnt/KINGSTON/cuda/bin:$KALDI_ROOT/src/base/:$KALDI_ROOT/src/nnet3bin/:$KALDI_ROOT/src/online2bin/:$KALDI_ROOT/src/ivectorbin/:$KALDI_ROOT/src/chainbin/:$PWD:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/KINGSTON/cuda/lib64
# Defining audio data directory (modify it for your installation directory!)
export DATA_ROOT="/mnt/KINGSTON/Kaldi/kaldi/egs/bisaya/samples"
# Enable SRILM
. $KALDI_ROOT/tools/env.sh
# Variable needed for proper data sorting
export LC_ALL=C
export PYTHONUNBUFFERED=1
