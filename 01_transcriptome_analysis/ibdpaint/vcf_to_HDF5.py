#!/usr/bin/env python

"""
A wrapper for scikit-allel to convert a VCF file to HDF5.

Adpated from code at http://scikit-allel.readthedocs.io/en/latest/io.html#allel.vcf_to_hdf5

Tom Ellis, 19th December 2023

Input:
    VCF file.
Output:
    HDF5 files maintaining all the fields in the VCF.
"""

import argparse
import allel
print('scikit-allel', allel.__version__)

inOptions = argparse.ArgumentParser(description='A wrapper for scikit-allel to convert a VCF file to HDF5 ')
inOptions.add_argument(
    "--input",
    help="Path to the input VCF.",
    type = str
    )
inOptions.add_argument(
    "--output",
    help = "Destination path for the output HDF5 file.",
    type=str
    )
args = inOptions.parse_args()

allel.vcf_to_hdf5(
    args.input,
    args.output,
    fields='*', overwrite=True
    )