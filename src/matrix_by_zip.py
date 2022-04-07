from typing import Any


import os
from dotenv import load_dotenv
import requests
import json
import pandas as pd
import functools


load_dotenv()
API_KEY = os.getenv('SAFEGRAPH_API_KEY')


# this query returns up to 20 places
# but you can iterate through to make it 
# look for all the ones in the zip code.
def make_places_query(zip_code : str) -> str:
    q = """
    query {
      search(
        filter: {
          address: { 
            postal_code : """ + f"""
            "{zip_code}"
            """ + """\n
          }
        }
      ) {
        places {
          results {
            edges {
              node {
                safegraph_core {
                  location_name
                  placekey
                  latitude
                  longitude
                  street_address
                  city
                  region
                  postal_code
                  iso_country_code
                  brands {
                    brand_id
                    brand_name
                  }
                }
                safegraph_geometry {
                  polygon_wkt
                  polygon_class
                  includes_parking_lot
                  is_synthetic
                  enclosed
                }
              }
            }
            }
        }
      }
    }
    """
    return(q)

def make_patterns_query(placekey : str) -> str:
    q = """query {
          lookup(placekey: """ + f""" "{placekey}" """+ """ ) {
            monthly_patterns (start_date: "2022-01-01", end_date: "2022-02-28") {
              placekey
              location_name
              street_address
              city
              region
              postal_code
              brands {
                brand_id
                brand_name
              }
              date_range_start
              date_range_end
              raw_visit_counts
              raw_visitor_counts
              visits_by_day
              poi_cbg
              popularity_by_hour
              visitor_home_cbgs
              visitor_home_aggregation
              visitor_daytime_cbgs
              visitor_country_of_origin
              distance_from_home
              bucketed_dwell_times
              median_dwell
            }
          }
        }
    """
    return(q)

def make_safegraph_request(
    query: str,
    variables: dict[str,Any] = None
) -> dict[Any]:
    headers = {
        'Content-Type': 'application/json',
        'apikey': API_KEY,
    }
    safegraph_request = functools.partial(
        requests.post,url = 'https://api.safegraph.com/v2/graphql',
        headers=headers
    )
    if variables:
        r_json = safegraph_request(
            json= {"query" : query, "variables" : variables}
        ).json()
    else:
        r_json = safegraph_request(json= {"query" : query}).json()
    return r_json


def places_resp_to_dataframe(resp: dict[str,Any]) -> pd.DataFrame:
    dfs = []
    for i in resp["data"]["search"]["places"]["results"]["edges"]:
        dfs.append(pd.json_normalize(i["node"]["safegraph_core"]))
    return pd.concat(dfs)


def get_placekey_list(resp: dict[str,Any]) -> list:
    placekeys: list = []
    for i in resp["data"]["search"]["places"]["results"]["edges"]:
        placekeys.append(i["node"]["safegraph_core"]["placekey"])
    return placekeys
    

def patterns_resp_to_dataframe(
    placekey_list: list,
) -> pd.DataFrame:
    dfs = []
    for pk in placekey_list:
        query = make_patterns_query(pk)
        resp = make_safegraph_request(query)
        if resp["data"]["lookup"]["monthly_patterns"]:
            dfs.append(
                pd.json_normalize(
                    resp["data"]["lookup"]["monthly_patterns"],
                    max_level=0
                )
            )
    return pd.concat(dfs)

def make_cbgs_matrix(patterns: pd.DataFrame) -> pd.DataFrame :
    mat = pd.json_normalize(patterns.visitor_home_cbgs)
    mat = mat.set_index([patterns.poi_cbg,patterns.date_range_start])
    
    # aggregation over cbg or over cbg/time-period
    agg_mat = mat.groupby(level=0).sum()
    agg_mat = agg_mat.groupby(agg_mat.columns,axis=0).sum()
    return agg_mat
    
def get_places_for_zip(zip_code: str) -> list:
    query = make_query(zip_code)
    resp = make_safegraph_request(query)
    placekeys = get_placekey_list(resp)
    return placekeys

def get_matrix_for_zip(zip_code: str) -> pd.DataFrame:
    placekeys = get_places_for_zip(zip_code)
    patterns = patterns_resp_to_dataframe(placekeys)
    mat = make_cbgs_matrix(patterns)
    return mat
    
    