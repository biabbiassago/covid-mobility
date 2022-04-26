from typing import Any
from typing import Dict
from typing import List 

import os
from dotenv import load_dotenv
import requests
import json
import pandas as pd
import functools


load_dotenv()
API_KEY = os.getenv('SAFEGRAPH_API_KEY')

# this query returns up to 1000 places
## TODO: check returning in full (?)

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
          results (first: 1000, after: ""){
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


def places_resp_to_dataframe(resp: Dict[str,Any]) -> pd.DataFrame:
    
    dfs = []
    for i in resp["data"]["search"]["places"]["results"]["edges"]:
        dfs.append(pd.json_normalize(i["node"]["safegraph_core"]))
    return pd.concat(dfs).reset_index(drop=True)

def make_patterns_query(placekey : str, start_date: str, end_date: str) -> str:
    q = """query {
          lookup(placekey: """ + f""" "{placekey}" """+ """ ) {
            weekly_patterns (start_date: """ + f""" "{start_date}", end_date: "{end_date}" """ + """) {
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
              poi_cbg
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


def get_placekey_list(resp: Dict[str,Any]) -> List[str]:
    
    placekeys: List = []
    for i in resp["data"]["search"]["places"]["results"]["edges"]:
        placekeys.append(i["node"]["safegraph_core"]["placekey"])
    return placekeys
    

def patterns_resp_to_dataframe(
    placekey_list: List[str],
    start_date: str,
    end_date: str,
) -> pd.DataFrame:
    
    dfs = []
    for pk in placekey_list:
        query = make_patterns_query(pk, start_date, end_date)
        resp = make_safegraph_request(query)
        if resp["data"]["lookup"]["weekly_patterns"]:
            dfs.append(
                pd.json_normalize(
                    resp["data"]["lookup"]["weekly_patterns"],
                    max_level=0
                )
            )
    if not dfs:
        # if nothing is found return empty list 
        # note that this does not match output type
        # so use with care.
        return []
    return pd.concat(dfs)

def make_safegraph_request(
    query: str,
    variables: Dict[str,Any] = None
) -> Dict[Any]:
    
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


# Example use for zip code 
# query = make_places_query("11733")
# resp = make_safegraph_request(query)
# df = places_resp_to_dataframe(resp)


START_DATE = "2020-03-01"
END_DATE = "2020-12-31"

query = make_places_query("92617")
resp = make_safegraph_request(query)
placekeys = get_placekey_list(resp)
patterns = patterns_resp_to_dataframe(placekeys, START_DATE, END_DATE)