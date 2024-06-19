#!/bin/bash

# Define directories
DATA_DIR="/mnt/d/GLC/CAMS/raw"
OUTPUT_DIR="/mnt/d/GLC/CAMS/results/isopleths"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Define netCDF files and CAMS fields
declare -a files=("HrMax.nc" "MaxDay.nc" "YrAvg.nc" "HrStd.nc" "ANOVA_std_Mth.nc" "ANOVA_std_Hr.nc" "ANOVA_avg_Mth_01.nc" "ANOVA_avg_Mth_04.nc" "ANOVA_avg_Mth_07.nc" "ANOVA_avg_Mth_10.nc")
declare -a fields=("u10" "v10" "d2m" "t2m" "t" "msl" "pm10" "pm1" "pm2p5" "tcwv" "q" "co" "go3" "no2" "no" "so2" "c5h8" "hcho" "hno3" "h2o2" "c2h6" "oh" "pan" "c3h8" "aermr01" "aermr02" "aermr03" "aermr04" "aermr05" "aermr06" "aermr07" "aermr08" "aermr09" "aermr10" "aermr11" "tcco" "tc_c2h6" "tchcho" "tc_h2o2" "tc_oh" "tc_c5h8" "tc_ch4" "tc_hno3" "tcno2" "tc_no" "gtco3" "tc_pan" "tc_c3h8" "tcso2" "bcaod550" "duaod550" "omaod550" "ssaod550" "suaod550" "aod1240" "aod469" "aod550" "aod670" "aod865")

declare -a years=("2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023")
declare -a sfields=("no2" "so2" "pm2p5" "pm10" "aermr07")

# Define colormaps
declare -a colormaps=("viridis" "Greys" "gist_ncar" "coolwarm")  # Standard colormaps

# some alternatives that were considered declare -a colormaps=("viridis" "plasma" "inferno#" "Greys" "hsv" "gist_ncar" "gist_rainbow")  # Standard colormaps
 
# Create output folders for each colormap
for map in "${colormaps[@]}"; do
    mkdir -p "$OUTPUT_DIR/$map"
done

# Generate plots for each file, field, and colormap
for file in "${files[@]}"; do
    for field in "${fields[@]}"; do
        for colormap in "${colormaps[@]}"; do
            echo "Processing $field in $file using $colormap colormap..."
            python3 plot_netcdf.py "$DATA_DIR/$file" "$field" "$OUTPUT_DIR/$colormap/${field}_${file%.nc}.jpg" "$colormap"
        done
    done
done

# generate plots for the normalisation and anomalities
for colormap in "${colormaps[@]}"; do
	for field in "${sfields[@]}"; do
		echo "Processing $field in normalisation using $colormap colormap..."
		python3 plot_netcdf.py "$DATA_DIR/HrMax_X.nc" "$field" "$OUTPUT_DIR/$colormap/${field}_HrMax_X.jpg" "$colormap"
		python3 plot_netcdf.py "$DATA_DIR/HrMax_LnX.nc" "$field" "$OUTPUT_DIR/$colormap/${field}_HrMax_LnX.jpg" "$colormap"
		for year in "${years[@]}"; do
			python3 plot_netcdf.py "$DATA_DIR/MaxHr_Anom_${year}.nc" "$field" "$OUTPUT_DIR/$colormap/${field}_MaxHr_Anom_${year}.jpg" "$colormap"
		done
	done
	
# Plotting q_tcwv
python3 plot_netcdf.py "$DATA_DIR/GLC_AOD.nc" "q_tcwv" "$OUTPUT_DIR/$colormap/q_tcwv.jpg" "$colormap"

# Plotting rSS
python3 plot_netcdf.py "$DATA_DIR/GLC_AOD.nc" "rSS" "$OUTPUT_DIR/$colormap/rSS.jpg" "$colormap"

# Plotting rDU
python3 plot_netcdf.py "$DATA_DIR/GLC_AOD.nc" "rDU" "$OUTPUT_DIR/$colormap/rDU.jpg" "$colormap"

# Plotting rOM
python3 plot_netcdf.py "$DATA_DIR/GLC_AOD.nc" "rOM" "$OUTPUT_DIR/$colormap/rOM.jpg" "$colormap"

# Plotting rBC
python3 plot_netcdf.py "$DATA_DIR/GLC_AOD.nc" "rBC" "$OUTPUT_DIR/$colormap/rBC.jpg" "$colormap"

# Plotting rSU
python3 plot_netcdf.py "$DATA_DIR/GLC_AOD.nc" "rSU" "$OUTPUT_DIR/$colormap/rSU.jpg" "$colormap"
 
 
 done 
 


echo "All fields processed."
