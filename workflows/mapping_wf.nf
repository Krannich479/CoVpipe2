include { index_bwa; bwa } from '../modules/bwa'
include { get_genomecov } from '../modules/bedtools'
include { index_bam } from '../modules/samtools'

workflow mapping {
    take: 
        illumina_reads
        reference_fasta
    main:

        index_bwa(reference_fasta)
        bwa(illumina_reads, index_bwa.out.collect()) |
            (index_bam & get_genomecov)
    emit:
        bam = bwa.out.bam
        index = index_bam.out.index
        coverage = get_genomecov.out.tsv
}