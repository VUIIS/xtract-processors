#!/usr/bin/env bash

t1_niigz=$(pwd)/../INPUTS/t1.nii.gz
bedpost_dir=$(pwd)/../INPUTS/bedpost_v3/BEDPOSTX
out_dir=$(pwd)/../OUTPUTS

# Work in the output dir
cd "${out_dir}"

# Registrations

# Rigid register T1 to DWI and resample to DWI geometry
flirt \
    -bins 256 -cost corratio -dof 6 -interp trilinear \
    -in "${t1_niigz}" \
    -ref "${bedpost_dir}"/nodif \
    -out t1_to_nodif \
    -omat t1_to_nodif.mat

# Apply brain mask to the resampled T1
fslmaths \
    t1_to_nodif \
    -mas "${bedpost_dir}"/nodif_brain_mask \
    T1_brain

# FIXME We are here

# Rigid register masked DWI to masked T1 (why?)
flirt \
 -in bedpostx/nodif_brain \
 -ref bedpostx/T1_brain \
 -omat bedpostx/xfms/diff2str.mat \
 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -cost corratio

convert_xfm \
 -omat bedpostx/xfms/str2diff.mat \
 -inverse bedpostx/xfms/diff2str.mat

# Affine register T1 to MNI template
flirt \
 -in bedpostx/T1_brain \
 -ref fsl/data/standard/MNI152_T1_2mm_brain \
 -omat bedpostx/xfms/str2standard.mat \
 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -cost corratio

convert_xfm \
 -omat bedpostx/xfms/standard2str.mat \
 -inverse bedpostx/xfms/str2standard.mat

convert_xfm \
 -omat bedpostx/xfms/diff2standard.mat \
 -concat bedpostx/xfms/str2standard.mat bedpostx/xfms/diff2str.mat

convert_xfm \
 -omat bedpostx/xfms/standard2diff.mat \
 -inverse bedpostx/xfms/diff2standard.mat

flirt \
 -in bedpostx/nodif_brain \
 -applyxfm -init bedpostx/xfms/diff2standard.mat \
 -out bedpostx/xfms/diff2standard \
 -paddingsize 0.0 -interp trilinear -ref fsl/data/standard/MNI152_T1_2mm_brain


# XTRACT
xtract -bpx <bedpostX folder> \
    -species HUMAN \
    -out <output folder> \
    -stdwarp bedpostx/xfms/standard2diff.mat bedpostx/xfms/diff2standard.mat \
    -p xtract-processors/custom-fx/protocols -str xtract-processors/custom-fx/customStructureList.txt

