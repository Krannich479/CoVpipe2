include { desh_qc; flagstat_table; fragment_size_table; fastp_table; kraken_table; coverage_table; multiqc_report } from '../modules/report'

workflow summary_report {
    take:
        consensus
        fastq_json
        kraken
        flagstat
        flagstat_csv
        mapping_fragment_size
        mapping_coverage
        president
        pangolin
        vois_tsv
        
    main:
        desh_qc(consensus, mapping_coverage, params.cov)
        desh_results = desh_qc.out.map {it -> it[1]}.collectFile(name: 'desh_results.tsv', skip: 1, keepHeader: true)

        fastp_table(fastq_json.map {it -> it[1]}.collect())

        kraken_table(kraken.map {it -> it[1]}.collect(), params.taxid)

        flagstat_table(flagstat_csv.map {it -> it[1]}.collect())

        fragment_size_table(mapping_fragment_size.map {it -> it[1]}.collect())
        
        coverage_table(mapping_coverage.map {it -> it[1]}.collect(), params.cov)

        president_results = president.map {it -> it[1]}.collectFile(name: 'president_results.tsv', skip: 1, keepHeader: true)
        
        pangolin_results = pangolin.map {it -> it[1]}.collectFile(name: 'pangolin_results.tsv', skip: 1, keepHeader: true)
        
        vois_results = vois_tsv.map {it -> it[1]}.collectFile(name: 'vois_results.tsv', skip: 1, keepHeader: true)

        multiqc_report(fastq_json.map {it -> it[1]}.collect(), kraken.map{ it -> it[1] }.collect(), flagstat.map{ it -> it[1] }.collect(), pangolin.map{ it -> it[1] }.collect())
}