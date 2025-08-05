#!/usr/bin/env bash

local/chain/run_tdnn.sh
utils/bestWER.sh
touch tdnnmodel1.txt
cp allBestWERS.txt tdnnmodel1.txt
rm -rf exp/nnet3 data/train_hires data/train_sp data/train_sp_hires data/test_hires data/train_sp_max2_hires

local/chain/run_tdnn.sh --exp_dir exp/tri3
utils/bestWER.sh
touch tdnnmodel2.txt
cp allBestWERS.txt tdnnmodel2.txt
rm exp/nnet3

local/chain/run_tdnn.sh --exp_dir exp/tri3 --epoch 10
utils/bestWER.sh
touch tdnnmodel3.txt
cp allBestWERS.txt tdnnmodel3.txt
rm exp/nnet3

local/chain/run_tdnn.sh --epoch 10
utils/bestWER.sh
touch tdnnmodel4.txt
cp allBestWERS.txt tdnnmodel4.txt
rm exp/nnet3
