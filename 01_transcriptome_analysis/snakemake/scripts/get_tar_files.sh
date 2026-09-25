# Find all tar.gz files that need extraction
find /groups/nordborg/projects/ddm1_resilencing/01_data/96_plates_tm3_rnaseq/*/  \
  -maxdepth 1 -name "*.tar.gz" -type f > tarballs_to_extract.txt

cat tarballs_to_extract.txt
