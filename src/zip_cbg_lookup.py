from typing import Any
from typing import List
from typing import Dict

import json
import numpy as np
import pandas as pd
from functools import reduce


# Download data file from https://www.huduser.gov/portal/datasets/usps_crosswalk.html

# Zip-Tract - for 1st quarter of 2020 (downloaded 04-15-2022)

def get_oc_zips() -> List[int] : 
    oc_zip_codes = pd.read_csv(
        "data/oc_covid_data_zip_weekly.csv",
        usecols=["zip"]
    )["zip"].unique()
    
    return oc_zip_codes

def make_lookup_dict(oc_zip_codes: np.array) -> Dict[int,int]:
    
    full_table = pd.read_csv("data/full_zip_tract_conversion.csv",
                             usecols=["ZIP","TRACT"]).rename(
        columns = {"ZIP":"zip","TRACT":"tract"}
    )
    only_oc = full_table[full_table.zip.isin(oc_zip_codes)]
    list_of_dicts = list(only_oc.apply(lambda x: {x.tract: x.zip}, axis=1))
    result_dict = reduce(lambda a, b: {**a, **b}, list_of_dicts)
    return result_dict

def oc_zip_cbg_lookup(cbg: str, oc_zip_codes: List[int], lookup_dict : Dict[int,int]) -> int:
    '''
    Returns zip code if zip is in OC, otherwise returns 11111
    '''
    try :
        current = int(cbg[1:-1])
    except:
        current = 0
    if lookup_dict.get(current):
        return lookup_dict.get(current)
    return 11111
    
    
## example use
    
# GIVEN_CBG = "060590626143"

# oc_zip_codes = get_oc_zips()
# lookup_dict = make_lookup_dict(oc_zip_codes)
# result_zip_code = oc_zip_cbg_lookup(GIVEN_CBG,oc_zip_codes,lookup_dict)


