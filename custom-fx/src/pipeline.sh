#!/usr/bin/env bash

# Registrations
flirt \
 -in t1 \
 -ref bedpostx/nodif \
 -out t1_nodif \
 -omat t1_2_nodif.mat \
 -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -interp trilinear

fslmaths \
 t1_2_nodif \
 -mas bedpostx/nodif_brain_mask.nii.gz \
 bedpostx/T1_brain.nii.gz

flirt \
 -in bedpostx/nodif_brain \
 -ref bedpostx/T1_brain \
 -omat bedpostx/xfms/diff2str.mat \
 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -cost corratio

convert_xfm \
 -omat bedpostx/xfms/str2diff.mat \
 -inverse bedpostx/xfms/diff2str.mat

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

