 awk '
  FNR==1{
    # derive base name without path
    n=split(FILENAME, p, "/"); fname=p[n]
    # strip from first underscore onward
    sub(/_.*/, "", fname)
  }
  /Uniquely mapped reads %/{
    split($0,a,"|"); gsub(/^[ \t]+|[ \t]+$/, "", a[2])
    print fname "\t" a[2]
  }
' *Log.final.out | awk 'BEGIN{print "file\tuniquely_mapped_%"}1' > uniqely_mapped_reads.txt
