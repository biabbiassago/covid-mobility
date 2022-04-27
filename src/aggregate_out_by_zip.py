import pandas as pd
import os
import glob

from get_covid_zips import UNIQUE_ZIPS

zip_num = int(sys.argv[1])

ZIP_CODE = UNIQUE_ZIPS[zip_num]
PATH = "../outputs/out_by_zip/"
csv_files = glob.glob(os.path.join(path, "*.csv"))

def get_data() -> pd.DataFrame:
    dfs = []
    for f in csv_files:
        dfs.append(pd.read_csv(f))
    df = pd.concat(dfs).query(f'origin_zip == {ZIP_CODE}')
    return df

def aggregate_and_save(df: pd.DataFrame) -> None:

    by_zip_out = df.groupby(df.date_range_start).number_of_visits.sum().to_frame()
    by_zip_out.insert(0,"poi_origin_zip" , value=ZIP_CODE)
    by_zip_out.to_csv(f"../outputs/out_by_origin/out_visits_for_{ZIP}.csv")

def main() -> None:
    df = get_data()
    aggregate_and_save()

    
if __name__ == "__main__":
    main()

