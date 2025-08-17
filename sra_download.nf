nextflow.enable.dsl=2

params.runtable = "${baseDir}/SraRunInfo.csv"
params.fastq = "${baseDir}/fastq"

process download {
    cpus 6
    maxRetries 3
    errorStrategy { (task.attempt <= maxRetries)  ? 'retry' : 'ignore' }
    publishDir "${params.fastq}", mode: 'copy'

    // Input Run ID from SraRunInfo.csv
    input:
    val(run)

    // Output .fastq or .fastq.gz files
    output:
    path("*.fastq*")

    // Shell script that uses fasterq-dump to download SRA .fastq, then pigz to recompress paired-end reads
    script:
    """
    /modules/sw/x86_64/Ubuntu/24.04/sra-tools/3.2.1/bin/fasterq-dump ${run} -e ${task.cpus} -f --split-files
    pigz -p ${task.cpus} *.fastq
    """
}

workflow {
    Channel
        .fromPath(params.runtable, checkIfExists: true)
        .splitCsv(header: true)
        .map { it.Run }
        .set { runs }

    runs | download
}