# 设置实验目录变量
EXP_DIR=exp
# 创建实验目录，如果不存在的话
mkdir -p $EXP_DIR

LEXICON_NAME='simple'
# 检查词典文件是否存在，如果不存在则生成词典
if [ ! -f "$EXP_DIR/$LEXICON_NAME.lexicon" ]; then
    echo "generating lexicon..."
    python local/generate_lexicon.py "$EXP_DIR/$LEXICON_NAME" --with-r --with-tone
    echo "lexicon done"
fi

# 检查是否已经重新组织过baker语料库，如果没有则进行重新组织
if [ ! -d $EXP_DIR/baker_corpus ]; then
    echo "reorganizing baker corpus..."
    python local/reorganize_baker.py --root-dir=~/datasets/BZNSYP --output-dir=$EXP_DIR/baker_corpus --resample-audio
    echo "reorganization done. Check output in $EXP_DIR/baker_corpus."
    echo "audio files are resampled to 16kHz"
    echo "transcription for each audio file is saved with the same namd in $EXP_DIR/baker_corpus "
fi

# 检测OOV（Out of Vocabulary，词汇表外的词）情况
echo "detecting oov..."
python local/detect_oov.py $EXP_DIR/baker_corpus $EXP_DIR/"$LEXICON_NAME.lexicon"
echo "detecting oov done. you may consider regenerate lexicon if there is unexpected OOVs."


# 设置MFA（Montreal Forced Aligner，蒙特利尔强制对齐器）下载目录
MFA_DOWNLOAD_DIR=local/

# 检查MFA安装包是否存在，如果不存在则下载
if [ ! -f "$MFA_DOWNLOAD_DIR/montreal-forced-aligner_linux.tar.gz" ]; then
    echo "downloading mfa..."
    (cd $MFA_DOWNLOAD_DIR && wget https://github.com/MontrealCorpusTools/Montreal-Forced-Aligner/releases/download/v1.0.1/montreal-forced-aligner_linux.tar.gz)
    echo "download mfa done!"
fi
# 检查MFA是否已解压，如果没有则解压
if [ ! -d "$MFA_DOWNLOAD_DIR/montreal-forced-aligner" ]; then
    echo "extracting mfa..."
    (cd $MFA_DOWNLOAD_DIR && tar xvf "montreal-forced-aligner_linux.tar.gz")
    echo "extraction done!"
fi
# 将MFA添加到PATH环境变量中
export PATH="$MFA_DOWNLOAD_DIR/montreal-forced-aligner/bin"
# 检查对齐结果目录是否存在，如果不存在则使用MFA进行训练和对齐
if [ ! -d "$EXP_DIR/baker_alignment" ]; then
    echo "Start MFA training..."
    # 使用MFA进行训练和对齐
    mfa_train_and_align $EXP_DIR/baker_corpus "$EXP_DIR/$LEXICON_NAME.lexicon" $EXP_DIR/baker_alignment -o $EXP_DIR/baker_model --clean --verbose --temp_directory $EXP_DIR/.mfa_train_and_align
    echo "training done!"
    # 输出训练结果和模型路径
    echo "results: $EXP_DIR/baker_alignment"
    echo "model: $EXP_DIR/baker_model"
fi

