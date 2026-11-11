##VEP==========================================================
##1.1下载 LOFTEE 插件
cd ~/vep_data2

# 安装 git（如果已经安装可以跳过）
# sudo apt-get install -y git

# 获取适用于 GRCh38 的 LOFTEE
git -c http.sslBackend=gnutls clone --depth 1 --branch grch38 \
  https://github.com/konradjk/loftee.git loftee

# 检查核心插件
ls -lh ~/vep_data2/loftee/LoF.pm



##1.2 下载 LOFTEE 参考数据

# ===== 1) 准备目录 =====
mkdir -p ~/vep_data2/loftee_data
cd ~/vep_data2/loftee_data

BASE_URL="https://personal.broadinstitute.org/konradk/loftee_data/GRCh38"

# ===== 2) 下载人类祖先序列及其索引 =====
wget -c "${BASE_URL}/human_ancestor.fa.gz"
wget -c "${BASE_URL}/human_ancestor.fa.gz.fai"
wget -c "${BASE_URL}/human_ancestor.fa.gz.gzi"

# ===== 3) 下载 PhyloCSF SQLite 数据库 =====
wget -c "${BASE_URL}/loftee.sql.gz"

# 解压为 LOFTEE 可读取的数据库
gzip -dc loftee.sql.gz > loftee.sql

# ===== 4) 下载 GERP BigWig 保守性评分 =====
wget -c "${BASE_URL}/gerp_conservation_scores.homo_sapiens.GRCh38.bw"

# ===== 4) 下载 GERP BigWig 保守性评分 =====(上面的链接一直拒绝访问，所以现在用的是这个，文件名一样，但是文件大小会更小一些)
wget -c \
"https://ftp.ensembl.org/pub/release-115/compara/conservation_scores/92_mammals.gerp_conservation_score/gerp_conservation_scores.homo_sapiens.GRCh38.bw"
# ===== 5) 检查文件 =====
ls -lh

##1.3创建包含 samtools 的 VEP 镜像，在原有 VEP 115.2 镜像基础上增加依赖，不改变 VEP 本身的版本

cd ~/vep_data2

# 创建 Dockerfile
cat > Dockerfile.loftee <<'EOF'
FROM ensemblorg/ensembl-vep:release_115.2

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      samtools \
      libdbd-sqlite3-perl && \
    rm -rf /var/lib/apt/lists/*

USER vep
EOF

# 构建新镜像
sudo docker build \
  -f Dockerfile.loftee \
  -t ensembl-vep:115.2-loftee .


##1.4正式开始注释


#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/vep_data2"
IN_DIR="$BASE/input"
OUT_DIR="$IN_DIR/result"

mkdir -p "$OUT_DIR"

sudo docker run --rm -t \
  -v "$BASE:/opt/vep/.vep" \
  -v "$BASE:/data" \
  --user "$(id -u):$(id -g)" \
 ensembl-vep:115.2-loftee \
  bash -lc '
    set -euo pipefail
    shopt -s nullglob

    mkdir -p /data/input/result

    # ===== 新增：设置 LOFTEE Perl 模块搜索路径 =====
    export PERL5LIB="/data/loftee:${PERL5LIB:-}"

    for f in /data/input/*.vcf /data/input/*.vcf.gz; do
      [ -e "$f" ] || continue

      bn=$(basename "$f")
      base=${bn%.gz}
      base=${base%.vcf}

      out="/data/input/result/${base}.vep.vcf"

      echo "[VEP + LOFTEE] $bn  ->  $(basename "$out")" >&2

      vep -i "$f" \
          -o "$out" \
          --vcf --force_overwrite \
          --cache --offline --dir_cache /opt/vep/.vep \
          --assembly GRCh38 \
          --fasta /opt/vep/.vep/Homo_sapiens.GRCh38.dna.toplevel.fa.bgz \
          --hgvs --hgvsg \
          --symbol --canonical --mane \
          --variant_class \
          --check_existing \
          --shift_hgvs 0 \
          --distance 500 \
          --dir_plugins /data/loftee \
          --plugin LoF,loftee_path:/data/loftee/,human_ancestor_fa:/data/loftee_data/human_ancestor.fa.gz,conservation_file:/data/loftee_data/loftee.sql,gerp_bigwig:/data/loftee_data/gerp_conservation_scores.homo_sapiens.GRCh38.bw \
          --fields "Allele,Consequence,IMPACT,SYMBOL,Gene,Feature,Existing_variation,HGVSc,HGVSp,MANE_SELECT,CANONICAL,VARIANT_CLASS,LoF,LoF_filter,LoF_flags,LoF_info" \
          --fork 4 --buffer_size 5000 --no_stats
    done
  '





##annovar====================================================

##3 annovar注释（当前最全的注释版本，各数据库都有）============================================
BASE="http://www.openbioinformatics.org/annovar/download"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_dbnsfp54a.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_dbnsfp54a.txt.idx.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_dbnsfp47a.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_dbnsfp47a.txt.idx.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_dbscsnv11.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_dbscsnv11.txt.idx.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_clinvar_20260829.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_clinvar_20260829.txt.idx.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_regsnpintron.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_regsnpintron.txt.idx.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_logofunc.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_logofunc.txt.idx.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_intervar_20250721.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_intervar_20250721.txt.idx.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_pubmind_db.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_pubmind_db.txt.idx.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_gnomad41_genome.txt.gz"

wget -c --tries=0 --timeout=60 --waitretry=10 \
    "${BASE}/hg38_gnomad41_genome.txt.idx.gz"

gunzip -k *.gz



##注释代码（dbnsfp54a版）
DB="/home/pan/配套数据及软件/annovar/newhumandb"   # 改成你实际存放数据库的目录

PROTO="refGene,cytoBand,knownGene,dbnsfp54a,dbscsnv11,clinvar_20260829,regsnpintron,logofunc,intervar_20250721,pubmind_db,gnomad41_genome"
OPER="gx,r,g,f,f,f,f,f,f,f,f"

for file in *.vcf; do
  table_annovar.pl "$file" "$DB" \
    -buildver hg38 \
    -out "${file%.vcf}_anno" \
    -protocol "$PROTO" \
    -operation "$OPER" \
    -remove -nastring . -vcfinput -polish
done



##注释代码（dbnsfp47a版，这一版有LRT 和 FATHMM，这两个是dbnsfp54a版没有的）=====================================================================================
DB="/home/pan/配套数据及软件/annovar/newhumandb"   # 改成你实际存放数据库的目录

PROTO="refGene,cytoBand,knownGene,dbnsfp47a,dbscsnv11,clinvar_20260829,regsnpintron,logofunc,intervar_20250721,pubmind_db,gnomad41_genome"
OPER="gx,r,g,f,f,f,f,f,f,f,f"

for file in *.vcf; do
  table_annovar.pl "$file" "$DB" \
    -buildver hg38 \
    -out "${file%.vcf}_anno" \
    -protocol "$PROTO" \
    -operation "$OPER" \
    -remove -nastring . -vcfinput -polish
done
