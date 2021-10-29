#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// help message
if (params.help) { exit 0, helpMSG() }

// error codes
if (params.profile) {
    exit 1, "--profile is WRONG use -profile" }
if (params.workdir) {
    exit 1, "--workdir is WRONG use -w" }

// warnings
if ( workflow.profile == 'standard' ) { 
    "NO EXECUTION PROFILE SELECTED, using [-profile local,conda]" }

if ( !workflow.revision ) { 
    println ""
    println "\u001B[31mWARN: no revision selected, please use -r for full reproducibility\033[0m"
}


/************************** 
* PARAMETERS
**************************/

if ( !params.fastq ) {
    exit 1, "input missing, use [--fastq]"
}

Set reference = ['sars-cov2'] // can be extended later on
if ( !params.reference && !params.ref_genome && !params.ref_annotation ) {
    exit 1, "reference missing, use [--ref_genome] (and [--ref_annotation]) or choose of " + reference + " with [--reference]"
}
if ( params.reference && params.ref_genome ) {
    exit 1, "too many references, use either [--ref_genome] (and [--ref_annotation]), or [--reference]"
}
if ( params.reference && ! (params.reference in reference) ) {
    exit 1, "unknown reference, currently supported: " + reference
}
// kraken input test
if (params.kraken && ! params.taxid) {
    exit 1, "Kraken2 database defined but no --taxid!"
}

/************************** 
* INPUT
**************************/

// load reference
if ( params.reference ) {
    if ( params.reference == 'sars-cov2' ) {
        referenceGenomeChannel = Channel
            .fromPath( workflow.projectDir + '/data/reference_SARS-CoV2/NC_045512.2.fasta' , checkIfExists: true )
        referenceAnnotationChannel = Channel
            .fromPath( workflow.projectDir + '/data/reference_SARS-CoV2/NC_045512.2.gff3' , checkIfExists: true )
    }
} else {
    referenceGenomeChannel = Channel
        .fromPath( params.ref_genome, checkIfExists: true )
}
if ( params.ref_annotation ) {
    referenceAnnotationChannel = Channel
        .fromPath( params.ref_annotation, checkIfExists: true )
}

// illumina reads input & --list support
if (params.mode == 'paired') {
    if (params.fastq && params.list) { fastqInputChannel = Channel
        .fromPath( params.fastq, checkIfExists: true )
        .splitCsv()
        .map { row -> [row[0], [file(row[1], checkIfExists: true), file(row[2], checkIfExists: true)]] }}
    else if (params.fastq) { fastqInputChannel = Channel
        .fromFilePairs( params.fastq, checkIfExists: true )}
} else {
    if (params.fastq && params.list) { fastqInputChannel = Channel
        .fromPath( params.fastq, checkIfExists: true )
        .splitCsv()
        .map { row -> [row[0], [file(row[1], checkIfExists: true)]] }}
    else if (params.fastq) { fastqInputChannel = Channel
        .fromPath( params.fastq, checkIfExists: true )
        .map { file -> [file.simpleName, [file]]}}
}

// load primers [optional]
if (params.primer) { primerInputChannel = Channel
        .fromPath( params.primer, checkIfExists: true)
        .collect()
}

// load adapters [optional]
if (params.adapter) { adapterInputChannel = Channel
        .fromPath( params.adapter, checkIfExists: true)
        .collect()
} else {
    adapterInputChannel = Channel
        .fromPath('NO_ADAPTERS')
        .collect()
}

/************************** 
* MODULES
**************************/

// preprocess & index
include { reference_preprocessing } from './workflows/reference_preprocessing_wf'

// clip & trim
include { trim_primer } from './workflows/trim_primer_wf'
include { read_qc } from './workflows/read_qc_wf'

// read taxonomy classification
include { download_kraken_db } from './workflows/kraken_download_wf'
include { classify_reads } from './workflows/classify_reads_wf'

// map
include { mapping } from './workflows/mapping_wf'

/************************** 
* MAIN WORKFLOW
**************************/
workflow {
    // 1: reference preprocessing
    reference_preprocessing(referenceGenomeChannel)
    reference_ch = reference_preprocessing.out.ref

    // 2: amplicon primer clipping [optional]
    if (params.primer) {
        trim_primer(fastqInputChannel, primerInputChannel)
    }
    reads_ch = params.primer ? trim_primer.out : fastqInputChannel

    // 3: quality trimming and optional adapter clipping [optional]
    reads_qc_ch = read_qc(reads_ch, adapterInputChannel).reads_trimmed

    // 4: taxonomic read classification [optional]
    if (params.kraken) {
        classify_reads(reads_qc_ch, download_kraken_db())
        kraken_reports = classify_reads.out.report
    }
    reads_qc_cl_ch = params.kraken ? classify_reads.out.reads : reads_qc_ch

    // 5: read mapping
    mapping(reads_qc_cl_ch, reference_ch)

}

/************************** 
* HELP
**************************/
def helpMSG() {
    c_green = "\033[0;32m";
    c_reset = "\033[0m";
    c_yellow = "\033[0;33m";
    c_blue = "\033[0;34m";
    c_red = "\u001B[31m";
    c_dim = "\033[2m";
    log.info """
    ____________________________________________________________________________________________
    
    ${c_blue}Robert Koch Institute, MF1 Bioinformatics${c_reset}

    Workflow: CoVpipeNext

    ${c_yellow}Usage examples:${c_reset}
    nextflow run CoVpipeNext.nf --fastq '*R{1,2}.fastq.gz' --reference 'sars-cov2' --cores 4 --max_cores 8
    or
    nextflow run RKIBioinformaticsPipelines/covpipenxt -r <version> --fastq '*R{1,2}.fastq.gz' --reference ref.fasta --cores 4 --max_cores 8

    ${c_yellow}Inputs:
    Illumina read data:${c_reset}
    ${c_green}--fastq ${c_reset}            e.g.: 'sample{1,2}.fastq' or '*.fastq.gz' or '*/*.fastq.gz'
    --list              this flag activates csv input for the above flags [default: false]
                        style of the csv is: ${c_dim}samplename,path_r1,path_r2${c_reset}
    --mode                     switch between 'paired'- and 'single'-end FASTQ 
    ${c_yellow}Reference:${c_reset}
    ${c_green}--reference ${c_reset}        currently supported: SARS-CoV2 (NC_045512)
    OR
    ${c_green}--ref_genome ${c_reset}       e.g.: 'ref.fasta'
    ${c_green}--ref_annotation ${c_reset}   e.g.: 'ref.fasta'
    """
}