/* Comments:
This is the "autodownload" process for the kraken database.
It features auto storage via cloud (line 2) or local storage (line 3)

We use "storeDir" in local mode - because its like a "persistant" process output,
this is automatically always checked by nextflow. Unfortunately, it's not usable for the cloud.
We use the "checkifexists" instead. (see main.nf code)
*/

process kraken_db {
    // label just some environment or container where we are sure that wget and tar are available
    label 'dos2unix'

    if (params.cloudProcess) { publishDir "${params.databases}/kraken", mode: 'copy', pattern: "GRCh38.p13_GBcovid19-2020-05-22" }
    else { storeDir "${params.databases}/kraken" }  

    output:
    path("GRCh38.p13_GBcovid19-2020-05-22", type: 'dir')

    script:
    """
    wget https://zenodo.org/record/3854856/files/GRCh38.p13_GBcovid19-2020-05-22.tar.gz?download=1 -O GRCh38.p13_GBcovid19-2020-05-22.tar.gz
    tar zxvf GRCh38.p13_GBcovid19-2020-05-22.tar.gz

    # the currently uploaded .tar.gz has a typo: GRC28.* instead of GRC38.*
    if [ -d "GRCh28.p13_GBcovid19-2020-05-22" ]; then
        mv GRCh28.p13_GBcovid19-2020-05-22 GRCh38.p13_GBcovid19-2020-05-22
    fi
    """
}

process kraken {
    label 'kraken'

    publishDir "${params.output}/${params.read_dir}/${name}/kraken", mode: params.publish_dir_mode, pattern: "*.txt"

    input:
    tuple val(name), path(reads)
    path(db)

    output:
    tuple val(name), file("${name}.classified.R_{1,2}.fastq.gz"),     emit: fastq
    tuple val(name), file("${name}.kraken.out.txt"),                  emit: kraken_output
    tuple val(name), file("${name}.kraken.report.txt"),               emit: kraken_report

    script:
    """
    ( kraken2 \
        --threads ${task.cpus} \
        --db ${db} \
        --paired \
        --classified-out ${name}.classified.R#.fastq.gz \
        --output ${name}.kraken.out.txt \
        --report ${name}.kraken.report.txt \
        --gzip-compressed \
        ${reads[0]} ${reads[1]} ) 2> ${name}.classify.log
    """
}

process filter_virus_reads {
    // label just some environment or container where we are sure that wget and tar are available
    label 'dos2unix'

    publishDir "${params.output}/${params.read_dir}/${name}/kraken/classified", mode: params.publish_dir_mode

    input:
    tuple val(name), path(reads)

    output:
    tuple val(name), file("${name}.classified.R{1,2}.fastq.gz"),    emit: fastq
    tuple val(name), file("${name}.extract.log"),                   emit: kraken_report

    script:
    """
    set +o pipefail
    zgrep -A3 'kraken:taxid|${params.taxid}' ${reads[0]} | sed -e 's/^--\$//' | sed '/^\\s*\$/d' | gzip 1> ${name}.classified.R1.fastq.gz 2>> ${name}.extract.log
    zgrep -A3 'kraken:taxid|${params.taxid}' ${reads[1]} | sed -e 's/^--\$//' | sed '/^\\s*\$/d' | gzip 1> ${name}.classified.R2.fastq.gz 2>> ${name}.extract.log
    """
}