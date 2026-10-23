library(data.table)
library(dplyr)
## Intersect data (bam) with metadata table and summary (number of aligned reads etc)
metadata <- fread("/groups/nordborg/projects/ddm1_resilencing/10_metadata/tm3_metadata_with_ibdpainting_all_samples.txt", header=T)
bam_sample_data <- fread("/groups/nordborg/projects/ddm1_resilencing/02_scripts/transposons-reactivation/01_transcriptome_analysis/snakemake/samples_uniq.tsv", header=T)
bam_sample_data_with_metadata <- left_join(bam_sample_data,metadata, by=c("sample_id"="Sample_id") )
summary_alignment <- fread("/scratch-cbe/users/elizaveta.grigoreva/ddm1_resilencing/processing/snakemake_run/summaries/stat_collected_0910.txt")
bam_sample_data_with_metadata_and_summary <- left_join(bam_sample_data_with_metadata,summary_alignment, by=c("unique_id"))
write.table(bam_sample_data_with_metadata_and_summary, "/groups/nordborg/projects/ddm1_resilencing/10_metadata/tm3_metadata_based_on_raw_bamfiles_with_summary.txt", quote = F, row.names = F, sep="\t")



####
data1 <- fread("/groups/nordborg/projects/ddm1_resilencing/03_processing/02_ibdpainting/tm3_genotype_samples_cut.txt", header=T)
data2 <- fread("/groups/nordborg/projects/ddm1_resilencing/03_processing/02_ibdpainting/samples_uniq2.tsv", header=T)
data3 <- left_join(data2, data1,by=c("sample_id"="Sample_id", "run"="Request_id"))
data3$mother <- "6909"
data3 <- data3 %>% select(unique_id,mother,Accession) 
write.table(data3,"/groups/nordborg/projects/ddm1_resilencing/03_processing/02_ibdpainting/expected_parents.txt", quote = F, row.names = F)

tm3set <- fread("/groups/nordborg/projects/ddm1_resilencing/03_processing/02_ibdpainting/expected_parents.txt", header=F)
colnames(tm3set) <-c("unique_id", "mother", "accession")
paper2set <- fread("/groups/nordborg/projects/ddm1_resilencing/01_data/pacbio_genomes_1001_phase2/Athaliana_assemblies_paper2.txt")
paper2set$Accession_ID <- as.numeric(as.character(paper2set$Accession_ID))
paper2set <- paper2set[!is.na(paper2set$Accession_ID), ]
joined_df_withlongreads <- left_join(tm3set,paper2set,by=c("accession"="Accession_ID"))
joined_df_withlongreads <- joined_df_withlongreads %>% select(unique_id,accession,Assembly_ID)
joined_df_withlongreads <- na.omit(joined_df_withlongreads)
write.table(joined_df_withlongreads,"/groups/nordborg/projects/ddm1_resilencing/01_data/pacbio_genomes_1001_phase2/accession_ids_intersected_with_tm3_dataset.csv", quote = F, row.names = F, sep="\t")
