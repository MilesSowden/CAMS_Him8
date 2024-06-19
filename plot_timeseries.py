import sys
import matplotlib.pyplot as plt
import numpy as np
import netCDF4 as nc
from scipy.spatial import cKDTree
import matplotlib.dates as mdates
from datetime import datetime

# Major cities data with latitude and longitude
cities = {
    "Sydney": (-33.8688, 151.2093),
    "Melbourne": (-37.8136, 144.9631),
    "Perth": (-31.9505, 115.8605),
    "Beijing": (39.9042, 116.4074),
    "Shanghai": (31.2304, 121.4737),
    "Guangdong": (23.1136, 113.2590),  
    "Kuala_Lumpur": (3.1390, 101.6869),
    "Bangkok": (13.7563, 100.5018),
    "Hanoi": (21.0285, 105.8542)
}

fields = ['no2', 'so2', 'pm2p5', 'pm10', 'pm1', 'aermr07', 'aermr09']

# Function to find the closest grid point in the NetCDF file
def find_closest_grid_point(nc_file, lat, lon):
    dataset = nc.Dataset(nc_file)
    lats = dataset.variables['latitude'][:]
    lons = dataset.variables['longitude'][:]
    # Find the index of the closest grid point
    lat_diff = np.abs(lats - lat)
    lon_diff = np.abs(lons - lon)
    lat_index = np.argmin(lat_diff)
    lon_index = np.argmin(lon_diff)
    return lat_index, lon_index

# Function to plot timeseries for a given city and field with common scale
def plot_timeseries(city, data, field, y_min, y_max):
    plt.figure(figsize=(15, 7))
    plt.plot(data['time'], data[field], label=field)
    plt.xlabel('Date', fontsize=24)
    plt.ylabel(field, fontsize=24)
    plt.title(f'Timeseries for {field} in {city}', fontsize=28)
    plt.gca().xaxis.set_major_locator(mdates.YearLocator())  # Set major ticks at yearly intervals
    plt.gca().xaxis.set_minor_locator(mdates.MonthLocator(interval=3))  # Set minor ticks at 3-month intervals
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
    plt.grid(which='both', linestyle='--')  # Show grid lines for both major and minor ticks
    plt.legend(fontsize=24)
    plt.xticks(rotation=45, fontsize=18)
    plt.yticks(fontsize=18)
    plt.tight_layout()
    plt.xlim(datetime(data['time'][0].year, 1, 1), datetime(data['time'][-1].year, 12, 31))  # Align to start and end year
    plt.ylim(y_min, y_max)
    plt.savefig(f'{city}_{field}_timeseries.jpg')
    plt.close()

# Main function
def main(nc_file):
    dataset = nc.Dataset(nc_file)
    
    # Determine common scale for each pollutant
    y_limits = {field: [np.inf, -np.inf] for field in fields}
    for city, (lat, lon) in cities.items():
        lat_index, lon_index = find_closest_grid_point(nc_file, lat, lon)
        for field in fields:
            if field in dataset.variables:
                var = dataset.variables[field]
                data = var[:, lat_index, lon_index]
                y_limits[field][0] = min(y_limits[field][0], np.nanmin(data))
                y_limits[field][1] = max(y_limits[field][1], np.nanmax(data))

    for city, (lat, lon) in cities.items():
        lat_index, lon_index = find_closest_grid_point(nc_file, lat, lon)
        time_var = dataset.variables['time']
        times = nc.num2date(time_var[:], time_var.units)
        times = [datetime(t.year, t.month, t.day) for t in times]  # Convert to datetime objects
        
        data = {'time': times}
        for field in fields:
            if field in dataset.variables:
                var = dataset.variables[field]
                data[field] = var[:, lat_index, lon_index]
                plot_timeseries(city, data, field, y_limits[field][0], y_limits[field][1])
            else:
                print(f"Field {field} not found in the dataset.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 plot_timeseries.py NetCDFfile")
        sys.exit(1)
    
    nc_file = sys.argv[1]
    main(nc_file)
