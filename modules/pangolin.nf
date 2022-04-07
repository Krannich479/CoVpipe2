process pangolin {
    label 'pangolin'
    container = params.pangolin_docker
    publishDir "${params.output}/${params.linage_dir}/${name}", mode: params.publish_dir_mode
    
    input:
    tuple val(name), path(fasta)
    val(pangolin_version)

    output:
    tuple val(name), path("${name}_lineage_report.csv"), emit: report

    script:
    """
    pangolin_version_curr=\$(pangolin --version)
    if [ "${pangolin_version}" != '' ]; then
        if [ "\$pangolin_version_curr" != "${pangolin_version}" ]; then
            echo "Something wrong in the pangolin update process."
            exit 1;
        fi
    fi
    pangolin --outfile ${name}_lineage_report.csv --tempdir . --threads ${task.cpus} ${fasta}
    """
    stub:
    """
    touch ${name}_lineage_report.csv
    used_pangolin_version=42
    scorpio_version=42
    scorpio_constellations_version=42
    """
}

process update_pangolin_conda_env {
    // execute this locally - would most likely fail on custer systems
    label 'pangolin'
    executor 'local'
    cpus 1
    cache false
    
    output:
    env(pangolin_version)

    script:
    conda_mode = workflow.profile.contains('mamba') ? 'mamba' : 'conda'
    """
    ${conda_mode} update pangolin
    pangolin_version=\$(pangolin --version)
    """
    stub:
    """
    pangolin_version=42 
    """
}