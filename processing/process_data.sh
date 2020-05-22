#!/bin/bash
#
# Process data.
#
# Usage:
#   ./process_data.sh <SUBJECT>
#
# Authors: Julien Cohen-Adad

# The following global variables are retrieved from parameters.sh but could be
# overwritten here:
# PATH_QC="~/qc"

# Uncomment for full verbose
# set -v

# Immediately exit if error
set -e -o pipefail

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
SUBJECT=$1


# FUNCTIONS
# ==============================================================================

# If there is an additional b=0 scan, add it to the main DWI data and update the
# bval and bvec files.
concatenate_b0_and_dwi(){
  local file_b0="$1"  # does not have extension
  local file_dwi="$2"  # does not have extension
  if [ -e ${file_b0}.nii.gz ]; then
    echo "Found additional b=0 scans: $file_b0.nii.gz They will be concatenated to the DWI scans."
    sct_dmri_concat_b0_and_dwi -i ${file_b0}.nii.gz ${file_dwi}.nii.gz -bval ${file_dwi}.bval -bvec ${file_dwi}.bvec -order b0 dwi -o ${file_dwi}_concat.nii.gz -obval ${file_dwi}_concat.bval -obvec ${file_dwi}_concat.bvec
    # Update global variable
    FILE_DWI="${file_dwi}_concat"
  else
    echo "No additional b=0 scans was found."
    FILE_DWI="${file_dwi}"
  fi
}

# Get specific field from json file
get_field_from_json(){
  local file="$1"
  local field="$2"
  echo `grep $field $file | sed 's/[^0-9]*//g'`
}

# Check if manual label already exists. If it does, copy it locally. If it does
# not, perform labeling.
label_if_does_not_exist(){
  local file="$1"
  local file_seg="$2"
  # Update global variable with segmentation file name
  FILELABEL="${file}_labels"
  if [ -e "${PATH_SEGMANUAL}/${file}_labels-manual.nii.gz" ]; then
    echo "Found manual label: ${PATH_SEGMANUAL}/${file}_labels-manual.nii.gz"
    rsync -avzh "${PATH_SEGMANUAL}/${file}_labels-manual.nii.gz" ${FILELABEL}.nii.gz
  else
    # Generate labeled segmentation
    sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg}.nii.gz -c t1
    # Create labels in the cord at C3 and C5 mid-vertebral levels
    sct_label_utils -i ${file_seg}_labeled.nii.gz -vert-body 3,5 -o ${FILELABEL}.nii.gz
  fi
}

# Check if manual segmentation already exists. If it does, copy it locally. If
# it does not, perform seg.
segment_if_does_not_exist(){
  local file="$1"
  local contrast="$2"
  # Update global variable with segmentation file name
  FILESEG="${file}_seg"
  if [ -e "${PATH_SEGMANUAL}/${FILESEG}-manual.nii.gz" ]; then
    echo "Found manual segmentation: ${PATH_SEGMANUAL}/${FILESEG}-manual.nii.gz"
    rsync -avzh "${PATH_SEGMANUAL}/${FILESEG}-manual.nii.gz" ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    # Segment spinal cord
    sct_deepseg_sc -i ${file}.nii.gz -c $contrast -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}

# Check if manual segmentation already exists. If it does, copy it locally. If
# it does not, perform seg.
segment_gm_if_does_not_exist(){
  local file="$1"
  local contrast="$2"
  # Update global variable with segmentation file name
  FILESEG="${file}_gmseg"
  if [ -e "${PATH_SEGMANUAL}/${FILESEG}-manual.nii.gz" ]; then
    echo "Found manual segmentation: ${PATH_SEGMANUAL}/${FILESEG}-manual.nii.gz"
    rsync -avzh "${PATH_SEGMANUAL}/${FILESEG}-manual.nii.gz" ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_gm -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    # Segment spinal cord
    sct_deepseg_gm -i ${file}.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}



# SCRIPT STARTS HERE
# ==============================================================================
# Go to results folder, where most of the outputs will be located
cd $PATH_RESULTS
# Copy source images
mkdir -p data
cd data
cp -r $PATH_DATA/$SUBJECT .
# Go to anat folder where all structural data are located
cd ${SUBJECT}/anat/

# T1w
# ------------------------------------------------------------------------------
file_t1="${SUBJECT}_T1w"
# Reorient to RPI and resample to 1mm iso (supposed to be the effective resolution)
sct_image -i ${file_t1}.nii.gz -setorient RPI -o ${file_t1}_RPI.nii.gz
sct_resample -i ${file_t1}_RPI.nii.gz -mm 1x1x1 -o ${file_t1}_RPI_r.nii.gz
file_t1="${file_t1}_RPI_r"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t1 "t1"
file_t1_seg=$FILESEG
# Create labels in the cord at C2 and C5 mid-vertebral levels (only if it does not exist)
label_if_does_not_exist ${file_t1} ${file_t1_seg}
file_label=$FILELABEL
# Register to PAM50 template
sct_register_to_template -i ${file_t1}.nii.gz -s ${file_t1_seg}.nii.gz -l ${file_label}.nii.gz -c t1 -param step=1,type=seg,algo=centermassrot:step=2,type=seg,algo=syn,slicewise=1,smooth=0,iter=5:step=3,type=im,algo=syn,slicewise=1,smooth=0,iter=3 -qc ${PATH_QC} -qc-subject ${SUBJECT}
# Rename warping fields for clarity
mv warp_template2anat.nii.gz warp_template2T1w.nii.gz
mv warp_anat2template.nii.gz warp_T1w2template.nii.gz
# Warp template without the white matter atlas (we don't need it at this point)
sct_warp_template -d ${file_t1}.nii.gz -w warp_template2T1w.nii.gz -a 0 -ofolder label_T1w
# Generate QC report to assess vertebral labeing
sct_qc -i ${file_t1}.nii.gz -s label_T1w/template/PAM50_levels.nii.gz -p sct_label_vertebrae -qc ${PATH_QC} -qc-subject ${SUBJECT}
# Flatten scan along R-L direction (to make nice figures)
sct_flatten_sagittal -i ${file_t1}.nii.gz -s ${file_t1_seg}.nii.gz
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_t1_seg}.nii.gz -vert 2:3 -vertfile label_T1w/template/PAM50_levels.nii.gz -o ${PATH_RESULTS}/csa-SC_T1w.csv -append 1

# T2
# ------------------------------------------------------------------------------
file_t2="${SUBJECT}_T2w"
# Reorient to RPI and resample to 0.8mm iso (supposed to be the effective resolution)
sct_image -i ${file_t2}.nii.gz -setorient RPI -o ${file_t2}_RPI.nii.gz
sct_resample -i ${file_t2}_RPI.nii.gz -mm 0.8x0.8x0.8 -o ${file_t2}_RPI_r.nii.gz
file_t2="${file_t2}_RPI_r"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t2 "t2"
file_t2_seg=$FILESEG
# Flatten scan along R-L direction (to make nice figures)
sct_flatten_sagittal -i ${file_t2}.nii.gz -s ${file_t2_seg}.nii.gz
# Bring vertebral level into T2 space
sct_register_multimodal -i label_T1w/template/PAM50_levels.nii.gz -d ${file_t2_seg}.nii.gz -o PAM50_levels2${file_t2}.nii.gz -identity 1 -x nn
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_t2_seg}.nii.gz -vert 2:3 -vertfile PAM50_levels2${file_t2}.nii.gz -o ${PATH_RESULTS}/csa-SC_T2w.csv -append 1

# MTS
# ------------------------------------------------------------------------------
file_t1w="${SUBJECT}_acq-T1w_MTS"
file_mton="${SUBJECT}_acq-MTon_MTS"
file_mtoff="${SUBJECT}_acq-MToff_MTS"

if [[ -e "${file_t1w}.nii.gz" && -e "${file_mton}.nii.gz" && -e "${file_mtoff}.nii.gz" ]]; then
  # Fetch TR and FA from the json files
  FA_t1w=$(get_field_from_json ${file_t1w}.json FlipAngle)
  FA_mton=$(get_field_from_json ${file_mton}.json FlipAngle)
  FA_mtoff=$(get_field_from_json ${file_mtoff}.json FlipAngle)
  TR_t1w=$(get_field_from_json ${file_t1w}.json RepetitionTime)
  TR_mton=$(get_field_from_json ${file_mton}.json RepetitionTime)
  TR_mtoff=$(get_field_from_json ${file_mtoff}.json RepetitionTime)
  # Segment spinal cord (only if it does not exist)
  segment_if_does_not_exist $file_t1w "t1"
  file_t1w_seg=$FILESEG
  # Create mask
  sct_create_mask -i ${file_t1w}.nii.gz -p centerline,${file_t1w_seg}.nii.gz -size 35mm -o ${file_t1w}_mask.nii.gz
  # Crop data for faster processing
  sct_crop_image -i ${file_t1w}.nii.gz -m ${file_t1w}_mask.nii.gz -o ${file_t1w}_crop.nii.gz
  file_t1w="${file_t1w}_crop"
  # Register PD->T1w
  # Tips: here we only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
  sct_register_multimodal -i ${file_mtoff}.nii.gz -d ${file_t1w}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
  file_mtoff="${file_mtoff}_reg"
  # Register MT->T1w
  sct_register_multimodal -i ${file_mton}.nii.gz -d ${file_t1w}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
  file_mton="${file_mton}_reg"
  # Register template->T1w_ax (using template-T1w as initial transformation)
  sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d ${file_t1w}.nii.gz -dseg ${file_t1w_seg}.nii.gz -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=syn,metric=CC,iter=5,gradStep=0.5 -initwarp warp_template2T1w.nii.gz -initwarpinv warp_T1w2template.nii.gz
  # Rename warping field for clarity
  mv warp_PAM50_t12${file_t1w}.nii.gz warp_template2axT1w.nii.gz
  mv warp_${file_t1w}2PAM50_t1.nii.gz warp_axT1w2template.nii.gz
  # Warp template
  sct_warp_template -d ${file_t1w}.nii.gz -w warp_template2axT1w.nii.gz -ofolder label_axT1w -qc ${PATH_QC} -qc-subject ${SUBJECT}
  # Compute MTR
  sct_compute_mtr -mt0 ${file_mtoff}.nii.gz -mt1 ${file_mton}.nii.gz
  # Compute MTsat
  sct_compute_mtsat -mt ${file_mton}.nii.gz -pd ${file_mtoff}.nii.gz -t1 ${file_t1w}.nii.gz -trmt $TR_mton -trpd $TR_mtoff -trt1 $TR_t1w -famt $FA_mton -fapd $FA_mtoff -fat1 $FA_t1w
  # Extract MTR, MTsat and T1 in WM between C2 and C5 vertebral levels
  sct_extract_metric -i mtr.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -vertfile label_axT1w/template/PAM50_levels.nii.gz -o ${PATH_RESULTS}/MTR.csv -append 1
  sct_extract_metric -i mtsat.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -vertfile label_axT1w/template/PAM50_levels.nii.gz -o ${PATH_RESULTS}/MTsat.csv -append 1
  sct_extract_metric -i t1map.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -vertfile label_axT1w/template/PAM50_levels.nii.gz -o ${PATH_RESULTS}/T1.csv -append 1
else
  echo "WARNING: MTS dataset is incomplete."
fi

# t2s
# ------------------------------------------------------------------------------
file_t2s="${SUBJECT}_T2star"
# Compute root-mean square across 4th dimension (if it exists), corresponding to all echoes in Philips scans.
sct_maths -i ${file_t2s}.nii.gz -rms t -o ${file_t2s}_rms.nii.gz
file_t2s="${file_t2s}_rms"
# Bring vertebral level into T2s space
sct_register_multimodal -i label_T1w/template/PAM50_levels.nii.gz -d ${file_t2s}.nii.gz -o PAM50_levels2${file_t2s}.nii.gz -identity 1 -x nn
# Segment gray matter (only if it does not exist)
segment_gm_if_does_not_exist $file_t2s "t2s"
file_t2s_seg=$FILESEG
# Compute the gray matter CSA between C3 and C4 levels
# NB: Here we set -no-angle 1 because we do not want angle correction: it is too
# unstable with GM seg, and t2s data were acquired orthogonal to the cord anyways.
sct_process_segmentation -i ${file_t2s_seg}.nii.gz -angle-corr 0 -vert 3:4 -vertfile PAM50_levels2${file_t2s}.nii.gz -o ${PATH_RESULTS}/csa-GM_T2s.csv -append 1

# DWI
# ------------------------------------------------------------------------------
file_dwi="${SUBJECT}_dwi"
cd ../dwi
# If there is an additional b=0 scan, add it to the main DWI data
concatenate_b0_and_dwi "${SUBJECT}_acq-b0_dwi" $file_dwi
file_dwi=$FILE_DWI
file_bval=${file_dwi}.bval
file_bvec=${file_dwi}.bvec
# Separate b=0 and DW images
sct_dmri_separate_b0_and_dwi -i ${file_dwi}.nii.gz -bvec ${file_bvec}
# Segment cord (1st pass -- just to get a rough centerline)
sct_propseg -i ${file_dwi}_dwi_mean.nii.gz -c dwi
# Create mask to help motion correction and for faster processing
sct_create_mask -i ${file_dwi}_dwi_mean.nii.gz -p centerline,${file_dwi}_dwi_mean_seg.nii.gz -size 30mm
# Crop data for faster processing
sct_crop_image -i ${file_dwi}.nii.gz -m mask_${file_dwi}_dwi_mean.nii.gz -o ${file_dwi}_crop.nii.gz
# Motion correction
sct_dmri_moco -i ${file_dwi}_crop.nii.gz -bvec ${file_dwi}.bvec -x spline
file_dwi=${file_dwi}_crop_moco
file_dwi_mean=${file_dwi}_dwi_mean
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist ${file_dwi_mean} "dwi"
file_dwi_seg=$FILESEG
# Register template->dwi (using template-T1w as initial transformation)
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d ${file_dwi_mean}.nii.gz -dseg ${file_dwi_seg}.nii.gz -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=syn,metric=CC,iter=5,gradStep=0.5 -initwarp ../anat/warp_template2T1w.nii.gz -initwarpinv ../anat/warp_T1w2template.nii.gz
# Rename warping field for clarity
mv warp_PAM50_t12${file_dwi_mean}.nii.gz warp_template2dwi.nii.gz
mv warp_${file_dwi_mean}2PAM50_t1.nii.gz warp_dwi2template.nii.gz
# Warp template
sct_warp_template -d ${file_dwi_mean}.nii.gz -w warp_template2dwi.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
# Create mask around the spinal cord (for faster computing)
sct_maths -i ${file_dwi_seg}.nii.gz -dilate 3,3,3 -o ${file_dwi_seg}_dil.nii.gz
# Compute DTI using RESTORE
sct_dmri_compute_dti -i ${file_dwi}.nii.gz -bvec ${file_bvec} -bval ${file_bval} -method standard -m ${file_dwi_seg}_dil.nii.gz
# Compute FA, MD and RD in WM between C2 and C5 vertebral levels
sct_extract_metric -i dti_FA.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_RESULTS}/DWI_FA.csv -append 1
sct_extract_metric -i dti_MD.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_RESULTS}/DWI_MD.csv -append 1
sct_extract_metric -i dti_RD.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_RESULTS}/DWI_RD.csv -append 1
# Go back to parent folder
cd ..

# Verify presence of output files and write log file if error
# ------------------------------------------------------------------------------
FILES_TO_CHECK=(
  "anat/${SUBJECT}_T1w_RPI_r_seg.nii.gz"
  "anat/${SUBJECT}_T2w_RPI_r_seg.nii.gz"
  "anat/label_axT1w/template/PAM50_levels.nii.gz"
  "anat/mtr.nii.gz"
  "anat/mtsat.nii.gz"
  "anat/t1map.nii.gz"
  "anat/${SUBJECT}_T2star_rms_gmseg.nii.gz"
  "dwi/dti_FA.nii.gz"
  "dwi/dti_MD.nii.gz"
  "dwi/dti_RD.nii.gz"
  "dwi/label/atlas/PAM50_atlas_00.nii.gz"
)
for file in ${FILES_TO_CHECK[@]}; do
  if [ ! -e $file ]; then
    echo "${SUBJECT}/${file} does not exist" >> $PATH_LOG/_error_check_output_files.log
  fi
done
