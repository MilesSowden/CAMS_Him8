#!/bin/bash

# Base directory for all CAMS data operations
BASE_DIR="/mnt/d/GLC/CAMS"

# Define the directory for raw data and ensure it exists
RAW_DIR="$BASE_DIR/raw"
# Directories for processed outputs
SCRATCH="$BASE_DIR/temp"
TAYLOR_DIR="$BASE_DIR/taylor"
MONTHLY_DIR="$BASE_DIR/monthly"
DAILY_DIR="$BASE_DIR/daily"
HOURLY_DIR="$BASE_DIR/hourly"
MEAN_DIR="$BASE_DIR/mean"
ANOMALIES_DIR="$BASE_DIR/anomalies"
RESULTS_DIR="$BASE_DIR/results"

mkdir -p $TAYLOR_DIR $SCRATCH $MONTHLY_DIR $DAILY_DIR $HOURLY_DIR $MEAN_DIR $ANOMALIES_DIR $RESULTS_DIR

# Cleanup old files
#rm -rf $MONTHLY_DIR $DAILY_DIR $HOURLY_DIR $MEAN_DIR $ANOMALIES_DIR
#rm $RAW_DIR/data_*.nc

# Define the Taylor subroutine =======================================================================
process_taylor() {
# Array of variables
variables=("bcaod550" "duaod550" "msl" "omaod550" "pm10"
           "pm1" "pm2p5" "ssaod550" "suaod550" "aod1240" "aod469" "aod550" "aod670" "aod865" "tcco"
           "tc_c2h6" "tchcho" "tc_h2o2" "tc_oh" "tc_c5h8" "tc_ch4" "tc_hno3" "tcno2" "tc_no" "gtco3"
           "tc_pan" "tc_c3h8" "tcso2" "tcwv")

# Process and prepare data files by year
for year in {2016..2023}; do
    YEAR_DIR="$RAW_DIR"
    YEAR_TAYLOR_DIR="$TAYLOR_DIR/$year"

    mkdir -p $YEAR_TAYLOR_DIR
	rm -f $YEAR_TAYLOR_DIR/*.nc		#cleanup any old files

    # Compute time standard deviation for each variable
    echo "Computing time standard deviation for $year"
    cdo -b F32 timstd -sqrt "$YEAR_DIR/lvl_${year}.nc" "$YEAR_TAYLOR_DIR/timestd_${year}.nc" &

    # Compute correlation for each pair of variables
    for var_name1 in "${variables[@]}"; do
        for var_name2 in "${variables[@]}"; do
            echo "Computing correlation between $var_name1 and $var_name2 in $year"
            cdo -b F32 timcor -selname,$var_name1 "$YEAR_DIR/lvl_${year}.nc" -selname,$var_name2 "$YEAR_DIR/lvl_${year}.nc" "$YEAR_TAYLOR_DIR/correl_${var_name1}_${var_name2}_${year}.nc" &
        done
        wait
    done

    # Merge time standard deviation and merged correlation file
    echo "Merging time standard deviation and correlation for $year"
    cdo -b F32 merge "$YEAR_TAYLOR_DIR/timestd_${year}.nc" "$YEAR_TAYLOR_DIR/correl_*_${year}.nc" "$YEAR_TAYLOR_DIR/merged_${year}.nc"
done

echo "Taylor variables analysis completed for all years."
echo "Please check the SPLIT step has done correctly."
echo "Press Enter when ready to continue."
read -p "Press [Enter] to continue..."
}

# Process and prepare data files by year ========================================================
process_scale() {
rm -f $SCRATCH/*.nc		#cleanup old files
for year in {2016..2023}; do
    # Processing sfc files
    echo "Processing $year sfc data for q parameter"
    cdo -b F32 setunit,"g/kg" -sqrt -mulc,1000 -selname,q "$RAW_DIR/sfc_${year}.nc" "$SCRATCH/q_${year}.nc"
    ncatted -a units,time,o,c,"hours since 1900-01-01 00:00:00.0" "$SCRATCH/q_${year}.nc"&

    echo "Processing $year sfc data for t parameter"
    cdo -b F32 setunit,"Degrees C" -subc,273.15 -selname,t "$RAW_DIR/sfc_${year}.nc" "$SCRATCH/t_${year}.nc"&

    echo "Processing $year sfc data for other parameters"
    cdo -b F32 sqrt -mulc,1E9 -delname,q,t "$RAW_DIR/sfc_${year}.nc" "$SCRATCH/conc_${year}.nc"
    ncatted -a units,,o,c,"ug/kg" -a units,time,o,c,"hours since 1900-01-01 00:00:00.0" "$SCRATCH/conc_${year}.nc"&

    # Processing lvl files
    echo "Processing $year lvl data for u10 and v10 parameters"
    cdo -b F32 selname,u10,v10 "$RAW_DIR/lvl_${year}.nc" "$SCRATCH/uv_${year}.nc"&

    echo "Processing $year lvl data for d2m parameter"
    cdo -b F32 setunit,"Degrees C" -subc,273.15 -selname,d2m "$RAW_DIR/lvl_${year}.nc" "$SCRATCH/d2m_${year}.nc"&

    echo "Processing $year lvl data for t2m parameter"
    cdo -b F32 setunit,"Degrees C" -subc,273.15 -selname,t2m "$RAW_DIR/lvl_${year}.nc" "$SCRATCH/t2m_${year}.nc"&
	
	echo "Processing $year lvl data for msl parameter"
    cdo -b F32 setunit,"kPa" -mulc,1E-3 -selname,msl "$RAW_DIR/lvl_${year}.nc" "$SCRATCH/msl_${year}.nc"&

    echo "Processing $year lvl data for aod parameters"
    cdo -b F32 selname,??aod*,aod* "$RAW_DIR/lvl_${year}.nc" "$SCRATCH/aod_${year}.nc"&

    echo "Processing $year lvl data for tcwv parameter"
    cdo -b F32 setunit,"kg/m^2" -selname,tcwv "$RAW_DIR/lvl_${year}.nc" "$SCRATCH/tcwv_${year}.nc"&

    echo "Processing $year lvl data for tc*, gtc* and pm* parameters"
    cdo -b F32 setunit,"mg/" -sqrt -mulc,1E6 -delname,tcwv -selname,tc*,gtc*,pm* "$RAW_DIR/lvl_${year}.nc" "$SCRATCH/tc_${year}.nc"
    ncatted -a units,,o,c,"mg/m^2" -a units,time,o,c,"hours since 1900-01-01 00:00:00.0" "$SCRATCH/tc_${year}.nc"
	wait 		#for parallel to finish
done
echo "Please check the SPLIT step has done correctly."
echo "Press Enter when ready to continue."
read -p "Press [Enter] to continue..."
}

# Process and prepare data files by year then split into monthly, daily and hourly ====================
process_MergeSplit() {
for year in {2016..2023}; do
    # Merging sfc and lvl processed data
#    echo "Merging processed data for $year"
#    cdo -b F32 merge "$SCRATCH/uv_${year}.nc" "$SCRATCH/d2m_${year}.nc" "$SCRATCH/t2m_${year}.nc" "$SCRATCH/t_${year}.nc" "$SCRATCH/msl_${year}.nc" "$SCRATCH/q_${year}.nc" "$SCRATCH/aod_${year}.nc" "$SCRATCH/tcwv_${year}.nc" "$SCRATCH/tc_${year}.nc" "$SCRATCH/conc_${year}.nc" "$RAW_DIR/data_${year}.nc"

    # Split files by months and then by days and hours
    echo "Splitting $year data by month, day, and hour"d2
    mkdir -p "$MONTHLY_DIR" "$DAILY_DIR" "$HOURLY_DIR"
    cdo splitmon "$RAW_DIR/data_${year}.nc" "$MONTHLY_DIR/Monthly_${year}"

    for month in $(seq -w 01 12); do
        MONTH_FILE="$MONTHLY_DIR/Monthly_${year}${month}.nc"
        # Split monthly file into daily files
        cdo splitday "$MONTH_FILE" "$DAILY_DIR/Daily_${year}${month}"

        for day in $(seq -w 01 31); do
            DAY_FILE="$DAILY_DIR/Daily_${year}${month}${day}.nc"
            # Check if day file exists to handle months with less than 31 days
            if [[ -f "$DAY_FILE" ]]; then
                # Split daily file into hourly files
                cdo splithour "$DAY_FILE" "$HOURLY_DIR/Hourly_${year}${month}${day}"&	#parallel
            fi
			wait
        done
    done
done

echo "Please check the merge into raw and split into hourly has been done correctly."
echo "Press Enter when ready to continue."
read -p "Press [Enter] to continue..."
# Remove all files in the scratch directory
rm -f $SCRATCH/*.nc
# Merge the necessary files
cdo -b F32 mergetime "$RAW_DIR"/data_{2016..2023}.nc "$RAW_DIR/data.nc"
clear; echo "All initial file preperation has completed successfully."

}

# create the statistics ========================================================================
process_GetStats() {

# Calculate maximum, mean, minimum, and standard deviation for the entire period
cdo -b F32 timmax "$RAW_DIR/data.nc" "$RAW_DIR/HrMax.nc" &
cdo -b F32 timmean "$RAW_DIR/data.nc" "$RAW_DIR/YrAvg.nc" &
cdo -b F32 timmin "$RAW_DIR/data.nc" "$RAW_DIR/HrMin.nc" &
cdo -b F32 sqrt -timstd "$RAW_DIR/data.nc" "$RAW_DIR/HrStd.nc" &
cdo -b F32 timmax -daymean "$RAW_DIR/data.nc" "$RAW_DIR/MaxDay.nc" &
wait

# Output information about each statistic to text files
cdo infov "$RAW_DIR/HrMax.nc" > "$RAW_DIR/HrMax_info.txt"
cdo infov "$RAW_DIR/YrAvg.nc" > "$RAW_DIR/YrAvg_info.txt"
cdo infov "$RAW_DIR/HrMin.nc" > "$RAW_DIR/HrMin_info.txt"
cdo infov "$RAW_DIR/HrStd.nc" > "$RAW_DIR/HrStd_info.txt"
cdo infov "$RAW_DIR/MaxDay.nc" > "$RAW_DIR/MaxDay_info.txt"

# Extract only the last five columns from each text file using awk
awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' "$RAW_DIR/HrMax_info.txt" > "$RAW_DIR/HrMax_cols.txt"
awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' "$RAW_DIR/YrAvg_info.txt" > "$RAW_DIR/YrAvg_cols.txt"
awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' "$RAW_DIR/HrMin_info.txt" > "$RAW_DIR/HrMin_cols.txt"
awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' "$RAW_DIR/HrStd_info.txt" > "$RAW_DIR/HrStd_cols.txt"
awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' "$RAW_DIR/MaxDay_info.txt" > "$RAW_DIR/MaxDay_cols.txt"

# Combine the selected columns from each file horizontally
paste "$RAW_DIR/HrMax_cols.txt" "$RAW_DIR/YrAvg_cols.txt" "$RAW_DIR/HrMin_cols.txt" "$RAW_DIR/HrStd_cols.txt" "$RAW_DIR/MaxDay_cols.txt" > "$RAW_DIR/combined_stats.txt"
}

#get the Anova calcs ===========================================================================
process_Anova() {

# Calculate standard deviation for all monthly data combined, then apply sqrt transformation
#cdo -b F32 sqrt -timstd -mergetime "$MONTHLY_DIR/Monthly_*.nc" "$RAW_DIR/ANOVA_std_Mth.nc"

# Calculate mean for all months
for month in $(seq -w 01 12); do cdo -b F32 timmean -mergetime $MONTHLY_DIR/"Monthly_*"${month}.nc $RAW_DIR/"ANOVA_avg_Mth_${month}.nc"; done

# Calculate standard deviation for all specific-hour data combined, then apply sqrt transformation
for hr in 00 03 06 09 12 15 18; do 
	echo $hr
  cdo -b F32 sqrt -timstd -mergetime "${HOURLY_DIR}/Hourly_*${hr}.nc" "${SCRATCH}/ANOVA_std_Hr_${hr}.nc"
done

cdo -b F32 timmean -mergetime "$SCRATCH/ANOVA_std_Hr_*.nc" "$RAW_DIR/ANOVA_std_Hr.nc"

echo "All ANOVA statistical calculations are complete."
echo "Please check the Anova calculations have been done correctly."
echo "Press Enter when ready to continue."
read -p "Press [Enter] to continue..."
}

# create the statistics
process_GetMeans() {
clear		# Step 2: Get means keep 2021 seperate for validation
for year in {2016..2023}; do
    for month in $(seq -w 01 12); do
        for hour in $(seq -w 00 3 21); do
            echo "Calculate time mean per year for "${year}" "${month}" "${hour}" and store in mean directory:"
             cdo timmean -mergetime "$HOURLY_DIR/Hourly_${year}${month}??${hour}.nc" "$MEAN_DIR/Mean_${year}${month}${hour}.nc" &
        done
		wait
    done
done

for month in $(seq -w 01 12); do				#combine the years into the Med file per month and hour 
	for hour in $(seq -w 00 3 21); do
		echo "Step 3: Calculate median per "${month}" "${hour}" and store in mean directory:"
 		cdo timmean -mergetime "$MEAN_DIR/Mean_????${month}${hour}.nc" "$MEAN_DIR/Med_${month}${hour}.nc" &
	done
	wait
done
cdo mergetime $MEAN_DIR/Med_*.nc $MEAN_DIR/median.nc
echo "Please check the merge into raw and split into hourly has been done correctly."
echo "Press Enter when ready to continue."
read -p "Press [Enter] to continue..."
}


# Calculate the deviation from the monthly_hour ===================================
process_Getanomalies() {
# Create directories if they do not exist
mkdir -p "$MEAN_DIR" "$ANOMALIES_DIR"
for year in {2016..2023}; do
    mkdir -p "$HOURLY_DIR/${year}" "$MEAN_DIR/${year}" "$ANOMALIES_DIR/${year}"
done

clear; echo "Step 3: Calculate anomalies for each month, day and hour and store in anomalies directory"
for year in {2016..2023}; do
    for month in $(seq -w 01 12); do
        for day in $(seq -w 01 31); do
            for hour in $(seq -w 00 3 21); do
                DAY_FILE="$HOURLY_DIR/Hourly_${year}${month}${day}${hour}.nc"
                # Check if day file exists to handle months with less than 31 days
                if [[ -f "$DAY_FILE" ]]; then        
                    echo ${year}${month}${day}${hour}
                    cdo sub "$DAY_FILE" "$MEAN_DIR/Med_${month}${hour}.nc" "$ANOMALIES_DIR/${year}/Anomalies_${year}${month}${day}${hour}.nc" &
                fi    # if 
            done    # hour 
			wait 
        done    # day 
    done    # month 
done    # year
cdo mergetime $ANOMALIES_DIR/{2016..2023}/Anomalies_*.nc "$ANOMALIES_DIR/anomalies.nc"

#make daily max anomalies file
for year in {2016..2023}; do cdo daymax $ANOMALIES_DIR/${year}/anomalies*.nc $ANOMALIES_DIR/${year}/daily_max_${year}.nc; done
cdo mergetime $ANOMALIES_DIR/{2016..2023}/daily_max_*.nc $ANOMALIES_DIR/daily_anom.nc

}

# Calculate the other ===================================
process_other() {
clear
for year in {2016..2023}; do
	echo "merge anomalies for " ${year}
#	cdo mergetime $ANOMALIES_DIR/${year}/Anomalies_*.nc "$ANOMALIES_DIR/${year}/anomalies.nc"
	
	echo "Determine maximum anomalies by year"
#	cdo -b F32 timmax "$ANOMALIES_DIR/${year}/anomalies.nc" $RAW_DIR/MaxHr_Anom_${year}.nc &
done 
wait

# Show normalization
echo "computing X and LnX"
cdo sqr $RAW_DIR/HrMax.nc $RAW_DIR/HrMax_X.nc 
cdo -b F32 ln -selname,no2,so2,pm10,aermr07 $RAW_DIR/HrMax_X.nc $RAW_DIR/HrMax_LnX.nc 

# Determine q/tcwv ratio working in raw directory
cdo -b F32 timmean -expr,'q_tcwv=q/tcwv; rSS=(aermr01+aermr02+aermr03)/ssaod550; rDU=(aermr04+aermr05+aermr06)/duaod550; rOM=(aermr07+aermr08)/omaod550; rBC=(aermr09+aermr10)/bcaod550; rSU=aermr11/suaod550' $RAW_DIR/data.nc $RAW_DIR/GLC_AOD.nc

echo "Finished" 
}

# Main script execution
echo "Starting the script..."

# Call the subroutine
process_taylor		#get The Taylor Plot Data, note this is a netCDF file not a single point
process_scale		#scale and change units of the raw data
process_MergeSplit	#merge the files into yearly, then split into monthly, daily and annually (to get monthly_hour mean)
process_GetStats 	#hourly daily annual maximum
process_Anova
process_GetMeans
process_Getanomalies
process_other


