import sys
import os
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import numpy as np
import netCDF4 as nc
import cartopy.crs as ccrs
import cartopy.feature as cfeature

#CAMS for the Vietnam bounding box?
#EPSG 4326 Bounding box:  xmin: 102.1446 ymin: 8.381355 xmax: 109.4692 ymax: 23.39269
vietnam_bounding_box_cities = {
    # Vietnam
    "Hanoi": (21.0285, 105.8542),
    "Ho Chi Minh City": (10.7769, 106.7009),
    "Da Nang": (16.0544, 108.2022),
    "Hai Phong": (20.8449, 106.6881),
    "Can Tho": (10.0452, 105.7469),
    "Nha Trang": (12.2388, 109.1967),
    "Hue": (16.4637, 107.5909),
    "Vung Tau": (10.4114, 107.1362),
    "Bien Hoa": (10.9473, 106.8231),
    
    # Cambodia
    "Phnom Penh": (11.5564, 104.9282),
    "Siem Reap": (13.3671, 103.8448),
    "Battambang": (13.0957, 103.2022),
    "Sihanoukville": (10.6253, 103.5234),
    "Kampong Cham": (12.0006, 105.4607),

    # Malaysia
    "Kuala Lumpur": (3.1390, 101.6869),
    
    # Thailand
    "Bangkok": (13.7563, 100.5018),
    
    # Laos
    "Vientiane": (17.9757, 102.6331),
    "Luang Prabang": (19.8833, 102.1333),
    
    # Singapore
    "Singapore": (1.3521, 103.8198)
}



# Major cities data with latitude and longitude
cities = {
    "Tokyo": (35.6895, 139.6917),
    "Seoul": (37.5665, 126.9780),
    "Sydney": (-33.8688, 151.2093),
    "Melbourne": (-37.8136, 144.9631),
    "Brisbane": (-27.4698, 153.0251),
  "Beijing": (39.9042, 116.4074),
"Shanghai": (31.2304, 121.4737),
"Chongqing": (29.4316, 106.9123),
"Guangdong": (23.1136, 113.2590),
"Port Moresby": (-9.4438, 147.1803),
    "Manila": (14.5995, 120.9842),
    "Jakarta": (-6.2088, 106.8456),
    "Singapore": (1.3521, 103.8198),
    "Kuala Lumpur": (3.1390, 101.6869),
    "Bangkok": (13.7563, 100.5018),
    "Hanoi": (21.0285, 105.8542),
    "Ho Chi Minh City": (10.7769, 106.7009),
    "Taipei": (25.0321, 121.5654),
    "Busan": (35.1796, 129.0756),
    "Perth": (-31.9505, 115.8605)
}

# List of countries with latitude and longitude, excluding India, including PNG
countries = {
    "Japan": (36.2048, 138.2529),
    "China": (35.8617, 104.1954),
    "Australia": (-25.2744, 133.7751),
    "South Korea": (35.9078, 127.7669),
    "Indonesia": (-0.7893, 113.9213),
    "Philippines": (12.8797, 121.7740),
    "Vietnam": (14.0583, 108.2772),
    "Thailand": (15.8700, 100.9925),
    "Malaysia": (4.2105, 101.9758),
    "Papua New Guinea": (-6.3149, 143.9555),
    "Brunei": (4.5353, 114.7277),
    "East Timor": (-8.8742, 125.7275),
    "Myanmar": (21.9162, 95.9560),
    "Java": (-7.6145, 110.7122),  # An island of Indonesia
    "Sumatra": (-0.5897, 101.3431)  # An island of Indonesia
}


def create_tab20hsv():
    """
    Create a colormap based on tab20 but with hues ordered like a rainbow.
    """
    tab20 = plt.cm.get_cmap('tab20', 20)  # Get the tab20 colormap
    colors = tab20(np.arange(20))  # Extract these colors as an array

    # Sort colors by hue value from the HSV space
    sorted_colors = sorted(colors, key=lambda x: mcolors.rgb_to_hsv(x[:3])[0])
    return mcolors.ListedColormap(sorted_colors)

def plot_variable_from_netcdf(nc_file, variable, output_file, colormap='viridis', dpi=600):

# Check if the custom colormap 'tab20hsv' is requested
    if colormap == 'tab20hsv':
        colormap = create_tab20hsv()  # Create the custom colormap

    # Open the netCDF file
    dataset = nc.Dataset(nc_file)
    
    # Read the specified variable
    data = dataset.variables[variable][:]
    
    # Extract long_name and units from the variable
    variable_long_name = dataset.variables[variable].long_name if 'long_name' in dataset.variables[variable].ncattrs() else variable
    variable_units = dataset.variables[variable].units if 'units' in dataset.variables[variable].ncattrs() else ''

    # Ensure data is 2D; squeeze out singleton dimensions
    data = data.squeeze()
    lat = dataset.variables['latitude'][:]
    lon = dataset.variables['longitude'][:]
      
    # Set up the plot with a geographic projection
    fig = plt.figure(figsize=(8,10))    # 6x9 inches, a typical portrait aspect ratio
    fig.subplots_adjust(left=0.05, right=0.95, top=0.90, bottom=0.05)
    ax = fig.add_subplot(1,1,1, projection=ccrs.PlateCarree())
    # Adjust the subplot parameters to reduce white space
    
    ax.set_extent([lon.min(), lon.max(), lat.min(), lat.max()], crs=ccrs.PlateCarree())
    
    # Add geographic features
    ax.add_feature(cfeature.COASTLINE)
    ax.add_feature(cfeature.BORDERS, linestyle=':')

    # Plot the data
    img = ax.pcolormesh(lon, lat, data, cmap=colormap, shading='auto', transform=ccrs.PlateCarree())
    plt.colorbar(img, ax=ax, orientation='horizontal', fraction=0.046, pad=0.04)
    
    # Add gridlines
    gl = ax.gridlines(draw_labels=True, linewidth=0.5, color='gray', alpha=0.5, linestyle='--')
    gl.top_labels = False
    gl.right_labels = False
    
    # Plot major cities
    for city, (lat, lon) in cities.items():
        ax.plot(lon, lat, 'ro', markersize=5, transform=ccrs.Geodetic())
        ax.text(lon + 0.5, lat, city, fontsize=10, transform=ccrs.Geodetic())
          
    # Extract only the file name _without_extension from the path for the title
    #file_name = os.path.basename(nc_file)
    file_name = os.path.splitext(os.path.basename(nc_file))[0]
    
    # Setting the title with a larger font size

    plt.title(f'{variable_long_name} _ {file_name}', fontsize=18)
    
    # Use tight_layout to optimize the spacing between parts of the figure
    plt.tight_layout()
    
    plt.savefig(output_file, format='jpg', dpi=dpi)
    plt.close()
    
    print(f'Saved {output_file}')

if __name__ == '__main__':
    nc_file = sys.argv[1]
    variable = sys.argv[2]
    output_file = sys.argv[3]
    colormap = sys.argv[4]
    
    plot_variable_from_netcdf(nc_file, variable, output_file, colormap)
