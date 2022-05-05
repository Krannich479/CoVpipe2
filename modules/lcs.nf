process lcs_ucsc_markers_table {
    label 'lcs_sc2'

    input:
    path(variant_group_tsv)

    output:
    path("LCS/outputs/variants_table/ucsc-markers-table-*.tsv")

    script:
    if ( params.lcs_ucsc_update || params.lcs_ucsc_default != 'predefined')
        """
        git clone https://github.com/rki-mf1/LCS.git

        if [[ "${variant_group_tsv}" != default ]]; then
            rm -rf LCS/data/variant_groups.tsv
            cp ${variant_group_tsv} LCS/data/variant_groups.tsv
        fi

        cd LCS
        ## change settings
        sed -i "s/PB_VERSION=.*/PB_VERSION='${params.lcs_ucsc}'/" rules/config.py
        sed -i "s/NUM_SAMPLE=.*/NUM_SAMPLE=${params.lcs_ucsc_downsampling}/" rules/config.py
        mem=\$(echo ${task.memory} | cut -d' ' -f1)
        ## run pipeline
        snakemake --cores ${task.cpus} --resources mem_gb=\$mem --config dataset=somestring markers=ucsc -- ucsc_gather_tables
        ## output
        mv outputs/variants_table/ucsc-markers-table.tsv outputs/variants_table/ucsc-markers-table-${params.lcs_ucsc}.tsv 
        """
    else if ( params.lcs_ucsc_default == 'predefined' )
        """
        git clone https://github.com/rki-mf1/LCS.git
        mkdir -p LCS/outputs/variants_table
        zcat LCS/data/pre-generated-marker-tables/ucsc-markers-2022-01-31.tsv.gz > LCS/outputs/variants_table/ucsc-markers-table.tsv
        mv LCS/outputs/variants_table/ucsc-markers-table.tsv LCS/outputs/variants_table/ucsc-markers-table-predefined.tsv 
        """
}

process lcs {
    label 'lcs_sc2'
    publishDir "${params.output}/${params.read_dir}/${name}/lineage-proportion-by-reads", mode: 'copy'
    
    input:
    tuple val(name), path(reads), path(ucsc_markers_table)
    
    output:
    tuple val(name), path("${name}.lcs.tsv")
    
    script:
    """
    git clone https://github.com/rki-mf1/LCS.git
    mkdir -p LCS/outputs/variants_table

    mv ${ucsc_markers_table} LCS/outputs/variants_table/ucsc-markers-table.tsv
    
    mkdir -p LCS/data/fastq
    if [ ${params.mode} == 'paired' ]; then
        cp ${reads[0]} LCS/data/fastq/${name}_1.fastq.gz
        cp ${reads[1]} LCS/data/fastq/${name}_2.fastq.gz
    else
        cp ${reads} LCS/data/fastq/${name}.fastq.gz
    fi
    echo ${name} > LCS/data/tags_pool_mypool
    
    cd LCS
    mem=\$(echo ${task.memory} | cut -d' ' -f1)
    snakemake --config markers=ucsc dataset=mypool --cores ${task.cpus} --resources mem_gb=\$mem --set-threads pool_mutect=${task.cpus}
    cd ..
    cp LCS/outputs/decompose/mypool.out ${name}.lcs.tsv

    rm -rf LCS/data/fastq
    """
    stub:
    """
    touch ${name}.lcs.tsv
    """
}

process lcs_plot {
    label "r"
    publishDir "${params.output}/${params.read_dir}/", mode: 'copy'

    input:
    path(tsv)
    val(cutoff)
    
    output:
    path("lcs_barplot.png")
    
    script:
    """
    lcs_bar_plot.R '${tsv}' ${cutoff}
    """
    stub:
    """
    touch lcs_barplot.png
    """
}