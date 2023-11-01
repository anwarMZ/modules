process KALLISTO_QUANT {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kallisto:0.48.0--h15996b6_2':
        'biocontainers/kallisto:0.48.0--h15996b6_2' }"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(index)
    path gtf
    path chromosomes

    output:
    tuple val(meta), path("${prefix}") , emit: results
    tuple val(meta), path("*info.json"), emit: json_info
    tuple val(meta), path("*.log.txt") , emit: log
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def gtf_input = gtf ? "--gtf ${gtf}" : ''
    def chromosomes_input = chromosomes ? "--chromosomes ${chromosomes}" : ''
    """
    kallisto quant \\
            --threads ${task.cpus} \\
            --index ${index} \\
            ${gtf_input} \\
            ${chromosomes_input} \\
            ${args} \\
            -o $prefix \\
            ${reads} 2> >(tee -a ${prefix}.log.txt >&2)

    if [ -f $prefix/run_info.json ]; then
        cp $prefix/run_info.json "${prefix}_run_info.json"
    fi
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kallisto: \$(echo \$(kallisto version) | sed "s/kallisto, version //g" )
    END_VERSIONS
    """

    stub:
    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kallisto: \$(echo \$(kallisto version) | sed "s/kallisto, version //g" )
    END_VERSIONS
    """
}
