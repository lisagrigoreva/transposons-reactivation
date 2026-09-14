"""
Run a non-parametric GWAS by performing a Kruskall-Wallis test at each locus.
This is done using phenotype data in Plink format and genotype data in HDF5 
format.

Inputs:
    - HDF5 file converted from a VCF file by allel.vcf_to_hdf5() from scikit-allel.
    - A phenotype file in Plink format (the same format used by GEMMA), with
      three columns and no headers:
        - Something blank
        - Sample IDs
        - Phenotypes
Output:
    - A CSV file giving chromosome, base position, Kruskall-Wallis statistic
      and associated p-values.

"""

import allel
import pandas as pd
import numpy as np
from scipy.stats import kruskal
from scipy import stats
import h5py
import warnings
import argparse
warnings.filterwarnings('ignore')

# hdf5_file = "03_processing/09_impute_haplotypes/output/parental_lines.hdf5"
# pheno="03_processing/06_process_phenotypes/output/flowering_time_blups_parents.tsv"

parser = argparse.ArgumentParser(
    description = "Run a Kruskall-Wallis GWAS using genotype data in HDF5 format."
)
parser.add_argument(
    '-g', '--hdf5_file',
    help='Path to an HDF5 file containing genotype data for one or more samples to check. This should be the output of allel.vcf_to_hdf5().',
    required=True
)
parser.add_argument(
    '-p', '--pheno',
    help="Phenotype file formatted for GEMMA. This should be tab delimited, usually with a column of zeroes, a column of sample names and one or more columns of phenotypes.",
    required=True
)
parser.add_argument(
    '-o', '--output',
    help="Path to an output file to save the results."
)
args=parser.parse_args()

# Import genotype data
callset = h5py.File(args.hdf5_file)
genotypes = allel.GenotypeArray(callset['calldata/GT'])
# Extract sample names and convert from byte to string.
sample_names = [x.decode('utf-8') for x in callset['samples'][:]]


# Import phenotype data
phenotypes = pd.read_csv(
    args.pheno, 
    sep='\t',
    names = ['FID', 'id', 'phenotype'],
    dtype = {'FID': str, "id":str, 'phenotype':float}
    )

# Filter and align phenotype data
pheno_filtered = phenotypes[phenotypes['id'].isin(sample_names)].copy()
pheno_filtered = pheno_filtered.set_index('id').reindex(sample_names).reset_index()

# Remove samples with missing phenotypes
valid_samples = ~pheno_filtered['phenotype'].isna()
pheno_filtered = pheno_filtered[valid_samples]
genotypes = genotypes[:, valid_samples, :]
print(f"Analyzing {len(pheno_filtered)} samples across {genotypes.shape[0]} SNPs")

# Convert to allele counts (0, 1, 2, or -1 for missing)
geno_counts = genotypes.count_alleles(max_allele=1)[:, 1]  # Count of alt alleles
geno_numeric = genotypes.to_n_alt(fill=-1)  # -1 for missing data

# Function to run the Kruskall-Wallis test
def kruskal_test_snp(snp_genotypes, phenotypes):
    """Perform Kruskal-Wallis test for a single SNP"""
    # Remove missing genotypes
    valid_mask = snp_genotypes != -1
    
    if valid_mask.sum() < 3:  # Need at least 3 samples
        return np.nan, np.nan
    
    valid_geno = snp_genotypes[valid_mask]
    valid_pheno = phenotypes[valid_mask]
    
    # Check if we have variation in genotypes
    unique_genos = np.unique(valid_geno)
    if len(unique_genos) < 2:
        return np.nan, np.nan
    
    # Group phenotypes by genotype
    groups = [valid_pheno[valid_geno == g] for g in unique_genos]
    
    # Remove empty groups
    groups = [g for g in groups if len(g) > 0]
    
    if len(groups) < 2:
        return np.nan, np.nan
    
    try:
        stat, pval = kruskal(*groups)
        return stat, pval
    except:
        return np.nan, np.nan
    

# Run tests for all SNPs
phenotype_values = pheno_filtered['phenotype'].values
results = []

for i in range(geno_numeric.shape[0]):
    stat, pval = kruskal_test_snp(geno_numeric[i], phenotype_values)
    if not np.isnan(stat):
        results.append({
            'chr': callset['variants/CHROM'][i].decode('utf-8'),
            'ps': callset['variants/POS'][i],
            'statistic': stat,
            'p_lrt': pval
        })

results_df = pd.DataFrame(results)

results_df.to_csv(args.output, index=False, sep='\t')

callset.close()
