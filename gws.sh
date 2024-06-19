#!/bin/bash

# Define directories
DATA_DIR="../CAMS/anomalies"
OUTPUT_DIR="../CAMS/gwr"
TEMP_DIR="../CAMS/temp"

# Define the years and fields
years=(2016 2017 2018 2019 2020 2021 2022 2023)
y_fields=("no2" "so2" "pm2p5" "pm10" "pm1" "aermr07" "aermr09")
x_fields=("xmsl" "xt" "xu" "xv" "xq")
# Small epsilon to avoid division by zero
epsilon=1e-10

# Ensure output directories exist
#mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

# Step 1: Process fields using cdo -expr
for year in "${years[@]}"; do
    input_file="$DATA_DIR/$year/anomalies.nc"
    
    # Handle potential division by zero for u10 and v10
#    cdo -expr,"xmsl=msl; xq=q; xu=u10; xv=v10; xt=1/(t2m+273.15); no2=no2; so2=so2; pm2p5=pm2p5; pm10=pm10; pm1=pm1; aermr07=aermr07; aermr09=aermr09" "$input_file" "$TEMP_DIR/${year}_processed.nc"
done

# Step 2: Merge the years into a single file
#cdo mergetime "$TEMP_DIR/*_processed.nc" "$TEMP_DIR/all_years.nc"

# Step 3: Calculate Max slope y/x for each hour and mean for the 8 years. Due to normalisation sqr first
for y_field in "${y_fields[@]}"; do
    for x_field in "${x_fields[@]}"; do
        #cdo sqrt -div -sqr -selname,$y_field "$TEMP_DIR/all_years.nc" -sqr -selname,$x_field "$TEMP_DIR/all_years.nc" "$TEMP_DIR/slope_${y_field}_over_${x_field}.nc"
        #cdo log -timmean "$TEMP_DIR/slope_${y_field}_over_${x_field}.nc" "$OUTPUT_DIR/mean_slope_${y_field}_over_${x_field}.nc"
echo done 
    done
done

# Step 4: Calculate time correlation between y and x fields
for y_field in "${y_fields[@]}"; do
    for x_field in "${x_fields[@]}"; do
        cdo timcor -sqr -selname,$y_field "$TEMP_DIR/all_years.nc" -abs -selname,$x_field "$TEMP_DIR/all_years.nc" "$OUTPUT_DIR/correlation_${y_field}_vs_${x_field}.nc"
echo done
    done
done

# Step 5: Calculate time standard deviation of the x fields
for x_field in "${x_fields[@]}"; do
	echo done
#    cdo timstd -selname,$x_field "$TEMP_DIR/all_years.nc" "$OUTPUT_DIR/std_${x_field}.nc"
done

# Step 6: Prepare summary table
#rm -rf output.txt 
#for file in *.nc; do echo "$file,$(cdo -s infov "$file" | awk 'NR==2 {split($0, parts, ":"); print parts[5]}')" >> output.txt; done

#plot the results
for y_field in "${y_fields[@]}"; do
    for x_field in "${x_fields[@]}"; do
        python3 plot_netcdf.py "$OUTPUT_DIR/mean_slope_${y_field}_over_${x_field}.nc" ${y_field} "$OUTPUT_DIR/mean_slope_${y_field}_over_${x_field}.jpg" "gist_ncar"
		python3 plot_netcdf.py "$OUTPUT_DIR/correlation_${y_field}_vs_${x_field}.nc" ${y_field} "$OUTPUT_DIR/correlation_${y_field}_vs_${x_field}.jpg" "gist_ncar"
		python3 plot_netcdf.py "$OUTPUT_DIR/std_${x_field}.nc" ${x_field} "$OUTPUT_DIR/std_${x_field}.jpg" "gist_ncar"
    done
done



# Clean up temporary files
#rm -r "$TEMP_DIR"
