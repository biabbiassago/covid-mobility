"""
The goal of this file is to get a dataframe with

zip_code_destination | zip_code | Number of Visits |

for a given zip_code destination.
This will save a file for that given zip code and then
they will all be aggregate to find out visits for a specific zip code
"""
import sys
import pandas as pd

from safegraph_requests import make_places_query
from safegraph_requests import make_patterns_query
from safegraph_requests import get_placekey_list
from safegraph_requests import make_safegraph_request
from safegraph_requests import patterns_resp_to_dataframe

from zip_cbg_lookup import get_oc_zips
from zip_cbg_lookup import make_lookup_dict
from zip_cbg_lookup import oc_zip_cbg_lookup

from matrix_by_zip import make_zip_out_visits
from get_covid_zips import UNIQUE_ZIPS


zip_num = int(sys.argv[1])

ZIP_CODE = UNIQUE_ZIPS[zip_num]
START_DATE = "2020-03-01"
END_DATE = "2020-12-31"


def main()-> None:
    
    query = make_places_query(ZIP_CODE)
    resp = make_safegraph_request(query)
    placekeys = get_placekey_list(resp)
    patterns = patterns_resp_to_dataframe(placekeys,START_DATE, END_DATE)

    if patterns:
        oc_zip_codes = get_oc_zips()
        lookup_dict = make_lookup_dict(oc_zip_codes)

        out_matrix = make_zip_out_visits(patterns, ZIP_CODE, oc_zip_codes,lookup_dict)
    else:
        out_matrix = pd.DataFrame({"poi_zip": [11111],
                 "origin_zip":[11111],
                 "date_range_start":[pd.NA],
                 "number_of_visits_std":[pd.NA],
                 "number_of_vists":[pd.NA]}).set_index(
                ["poi_zip","origin_zip","date_range_start"]
        )
    file_name = f"outputs/out_by_zip/{ZIP_CODE}.csv"
    out_matrix.to_csv(file_name)
        
if __name__ == "__main__":
    main()