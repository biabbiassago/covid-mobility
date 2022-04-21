import numpy as np
import pandas as pd

weekly = pd.read_csv("data/oc_covid_data_zip_weekly.csv")

UNIQUE_REQUESTS = zip(
    np.unique(weekly.start_date),
    np.unique(weekly.end_date),
    np.unique(weekly.zip)
)
UNIQUE_ZIPS = np.unique(weekly.zip)
    
    

    
