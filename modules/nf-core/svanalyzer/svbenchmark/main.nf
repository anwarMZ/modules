
process SVANALYZER_SVBENCHMARK {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/svanalyzer:0.35--pl526_0':
        'biocontainers/svanalyzer:0.35--pl526_0' }"

    input:
    tuple val(meta), path(test)
    tuple val(meta2),path(truth)
    tuple val(meta3),path(fasta)
    tuple val(meta4),path(fai)
    tuple val(meta5),path(bed)

    output:
    tuple val(meta), path("*.falsenegatives.vcf.gz"), emit: fns
    tuple val(meta), path("*.falsepositives.vcf.gz"), emit: fps
    tuple val(meta), path("*.distances")            , emit: distances
    tuple val(meta), path("*.log")                  , emit: log
    tuple val(meta), path("*.report")               , emit: report
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bed = bed ? "-includebed $bed" : ""
    def VERSION = '0.35' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    svanalyzer \\
        benchmark \\
        $args \\
        --ref $fasta \\
        --test $test \\
        --truth $truth \\
        --prefix $prefix \\
        $bed

    bgzip ${args2} --threads ${task.cpus} -c ${prefix}.falsenegatives.vcf > ${prefix}.falsenegatives.vcf.gz
    bgzip ${args2} --threads ${task.cpus} -c ${prefix}.falsepositives.vcf > ${prefix}.falsepositives.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        svanalyzer: ${VERSION}
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '0.35' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    touch ${prefix}.falsenegatives.vcf.gz
    touch ${prefix}.falsepositives.vcf.gz
    touch ${prefix}.distances
    touch ${prefix}.log
    touch ${prefix}.report

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        svanalyzer: ${VERSION}
    END_VERSIONS
    """
}
