#!/usr/bin/env bash
for i in 3
do
    currEx="/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples$i/"
    echo "Processing: ${currEx}/"

    cd data/train || exit
    mv prep.py ../
    rm -r *
    mv ../prep.py ./
    echo "Running prep.py in train..."
    python prep.py "${currEx}"
    

    cd ../test || exit
    mv prep.py ../
    rm -r *
    mv ../prep.py ./
    echo "Running prep.py in test..."
    python prep.py "${currEx}"

    cd ../../ || exit
    python finalize.py data/train/text data/local/dict/referenceW2Syll.txt text
    cp text data/train
    python finalize.py data/test/text data/local/dict/referenceW2Syll.txt text
    cp text data/test

    echo "Running main script..."
    ./run.sh --stage -6 --isolate false

    echo "Getting best WER..."
    utils/bestWER.sh
    touch run${i}bestWERS.txt
    cp allBestWERS.txt run${i}bestWERS.txt
done

