from typing import Any
from typing import Dict
from typing import List

import os
from dotenv import load_dotenv
import requests
import json
import pandas as pd
import functools

from safegraph_requests import make_safegraph_request
from safegraph_requests import make_places_query
from safegraph_requests import make_patterns_query

from zip_cbg_lookup import oc_zip_cbg_lookup


load_dotenv()
API_KEY = os.getenv('SAFEGRAPH_API_KEY')



def places_resp_to_dataframe(resp: Dict[str,Any]) -> pd.DataFrame:
    
    dfs = []
    for i in resp["data"]["search"]["places"]["results"]["edges"]:
        dfs.append(pd.json_normalize(i["node"]["safegraph_core"]))
    return pd.concat(dfs)

def make_cbgs_matrix(patterns: pd.DataFrame) -> pd.DataFrame :
    
    mat = pd.json_normalize(patterns.visitor_home_cbgs)
    mat = mat.set_index([patterns.poi_cbg,patterns.date_range_start])
    
    # aggregation over cbg or over cbg/time-period
    
    agg_mat = mat.groupby(level=0).sum()
    #agg_mat = agg_mat.groupby(agg_mat.columns,axis=0).sum()
    return agg_mat

def make_zip_out_visits(patterns: pd.DataFrame, zip_code: str, oc_codes: List[int], lookup_dict) -> pd.DataFrame:
    
    mat = pd.json_normalize(patterns.visitor_home_cbgs)
    mat = mat.set_index([patterns.poi_cbg,patterns.date_range_start])
    long_mat = mat.reset_index().melt(
        ["poi_cbg","date_range_start"],
        var_name="origin_cbg",
        value_name="number_of_visits"
    )
    long_mat = long_mat.dropna()
    long_mat["poi_zip"] = zip_code
    long_mat["origin_zip"] = long_mat.origin_cbg.apply(
        lambda x: oc_zip_cbg_lookup(x,oc_zip_codes=oc_codes,lookup_dict=lookup_dict)
    )
    
    # assume 4.0 = 1
    
    long_mat["number_of_visits_std"] = long_mat.number_of_visits.replace({4:1})
    
    out_matrix = long_mat.groupby(
        ["poi_zip","origin_zip","date_range_start"]
    )[["number_of_visits_std","number_of_visits"]].sum()
    
    return out_matrix

def get_places_for_zip(zip_code: str) -> List:
    
    query = make_places_query(zip_code)
    resp = make_safegraph_request(query)
    placekeys = get_placekey_list(resp)
    return placekeys


def get_matrix_for_zip_date(zip_code: str, start_date: str, end_date: str) -> pd.DataFrame:
    
    placekeys = get_places_for_zip(zip_code)
    patterns = patterns_resp_to_dataframe(placekeys, start_date, end_date)
    mat = make_cbgs_matrix(patterns)
    
    return mat

def get_patterns_for_zip(zip_code: str, start_date: str, end_date: str) -> pd.DataFrame:
    placekeys = get_places_for_zip(zip_code)
    patterns = patterns_resp_to_dataframe(placekeys, start_date, end_date)
    return patterns