process compress_reads {
  label 'pigz'

  input:
  tuple val(name), path(reads)

  output:
  tuple val(name), path("*.fastq.gz")

  script:
  """
  pigz -f -p ${task.cpus} ${reads}
  """
  stub:
  """
  touch fuu.fastq.gz
  """
}

process bgzip_compress {
  label 'samtools'

  publishDir "${params.publish_dir}/${name}", mode: params.publish_dir_mode

  input:
  tuple val(name), path(file)

  output:
  tuple val(name), path("${file}.gz")

  script:
  """
  bgzip -@ ${task.cpus} ${file}
  """
  stub:
  """
  touch ${file}.gz
  """
}

process adapt_consensus_header {
  publishDir "${params.output}/${params.consensus_dir}/${name}", mode: params.publish_dir_mode

  input:
  tuple val(name), path(fasta)

  output:
  tuple val(name), path("${name}.iupac_consensus.fasta")

  script:
  """
    VERSION='unknown_version'
    if [ ${workflow.revision} != 'null' ]; then
      VERSION=${workflow.revision}
    fi
    sed "1 s/.*/>${name}_iupac_consensus_\${VERSION}/" ${fasta} 1> ${name}.iupac_consensus.fasta
  """
  stub:
  """
  touch ${name}.iupac_consensus.fasta
  """
  }


process mask_iupac {
  publishDir "${params.output}/${params.consensus_dir}/${name}", mode: params.publish_dir_mode

  input:
  tuple val(name), path(fasta)

  output:
  tuple val(name), path("${name}.masked_consensus.fasta")

  script:
    """
      VERSION='unknown_version'
      if [ ${workflow.revision} != 'null' ]; then
        VERSION=${workflow.revision}
      fi
      echo ">${name}_masked_consensus_\${VERSION}\" 1> ${name}.masked_consensus.fasta 2> ${name}_createMaskedConsensus.log
      tail -n +2 ${fasta} | tr "RYSWKMBDHVN" "N" 1>> ${name}.masked_consensus.fasta 2>> ${name}_createMaskedConsensus.log
    """
  stub:
  """
  touch ${name}.masked_consensus.fasta
  """
}

process make_voi_table {
    label 'r'

    publishDir "${params.output}/${params.variant_calling_dir}/${name}", mode: params.publish_dir_mode

    input:    
    path(vois)
    tuple val(name), path(exact)
    tuple val(name), path(not_found)
    tuple val(name), path(low_coverage)
    tuple val(name), path(diff_voi)
    tuple val(name), path(diff_sample)

    output:
    tuple val(name), path("${name}_vois.csv")

    script:
    """
    #!/usr/bin/env Rscript
    library("dplyr")

    dt.voi <- read.table("${vois}", comment.char="#", colClasses = "character") # colClasses = "character" important, so that T is not interpreted as TRUE
    dt.voi <- dt.voi[c(1,2,3,4,5)] # get only the important stuff
    colnames(dt.voi) <- c("CHROM", "POS", "ID", "REF", "ALT")
    dt.voi\$key = paste(dt.voi\$CHROM, dt.voi\$POS, dt.voi\$REF, dt.voi\$ALT, sep="-")

    dt.voi_exact <- read.table("${exact}", comment.char="#", colClasses = "character", col.names = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "SAMPLE"))
    dt.voi_exact\$key = paste(dt.voi_exact\$CHROM, dt.voi_exact\$POS, dt.voi_exact\$REF, dt.voi_exact\$ALT, sep="-")
    dt.voi_not <- read.table("${not_found}", comment.char="#", colClasses = "character", col.names = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "SAMPLE"))
    dt.voi_not\$key = paste(dt.voi_not\$CHROM, dt.voi_not\$POS, dt.voi_not\$REF, dt.voi_not\$ALT, sep="-")
    dt.voi_low_cov <- read.table("${low_coverage}", comment.char="#", colClasses = "character", col.names = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "SAMPLE"))
    dt.voi_low_cov\$key = paste(dt.voi_low_cov\$CHROM, dt.voi_low_cov\$POS, dt.voi_low_cov\$REF, dt.voi_low_cov\$ALT, sep="-")
    dt.voi_diff_voi <- read.table("${diff_voi}", comment.char="#", colClasses = "character", col.names = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "SAMPLE"))
    dt.voi_diff_voi\$key = paste(dt.voi_diff_voi\$CHROM, dt.voi_diff_voi\$POS, dt.voi_diff_voi\$REF, dt.voi_diff_voi\$ALT, sep="-")
    dt.voi_diff_voi\$key2 = paste(dt.voi_diff_voi\$CHROM, dt.voi_diff_voi\$POS, dt.voi_diff_voi\$REF, sep="-")
    dt.voi_diff_sample <- read.table("${diff_sample}", comment.char="#", colClasses = "character", col.names = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "SAMPLE"))
    dt.voi_diff_sample\$key = paste(dt.voi_diff_sample\$CHROM, dt.voi_diff_sample\$POS, dt.voi_diff_sample\$REF, dt.voi_diff_sample\$ALT, sep="-")
    dt.voi_diff_sample\$key2 = paste(dt.voi_diff_sample\$CHROM, dt.voi_diff_sample\$POS, dt.voi_diff_sample\$REF, sep="-")

    dt.voi\$status <- case_when(dt.voi\$key %in% dt.voi_low_cov\$key ~ "low coverage", dt.voi\$key %in% dt.voi_not\$key ~ "not found", dt.voi\$key %in% dt.voi_exact\$key ~ "exact match", dt.voi\$key %in% dt.voi_diff_voi\$key ~ ifelse(is.null(dt.voi_diff_sample[dt.voi_diff_sample\$key2 == dt.voi_diff_voi\$key2]\$ALT), "na", dt.voi_diff_sample[dt.voi_diff_sample\$key2 == dt.voi_diff_voi\$key2]\$ALT))
    dt.voi <- cbind(sample = "${name}", dt.voi)
    write.csv(dt.voi[,!grepl("key",names(dt.voi))], quote = FALSE, row.names = FALSE, "${name}_vois.csv")
    """
    stub:
    """
    touch ${name}_vois.csv
    """
}
