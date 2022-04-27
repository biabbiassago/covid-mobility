import sys
import matplotlib.pylab as plt
import pandas as pd

from get_covid_zips import UNIQUE_ZIPS

zip_num = int(sys.argv[1])

ZIP_CODE = UNIQUE_ZIPS[zip_num]
PATH = f"outputs/out_by_origin/out_visits_for_{ZIP_CODE}.csv"

def load_data() -> pd.DataFrame:
    df = pd.read_csv(PATH).set_index("date_range_start")
    df.index = pd.to_datetime(df.index)
    return df


def make_out_plot(df: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(12, 6))
    df.number_of_visits.plot(ax=ax) 
    ax.set_title(f"Visits out of Zip Code {ZIP_CODE}",fontsize=16);
    ax.set_xlabel("");
    ax.set_ylabel("Number of visits to other OC codes",fontsize=12);
    fig.savefig(f"outputs/out_plots/{ZIP_CODE}.png")     

def main() -> None:
    df = load_data()
    make_out_plot(df)
    
if __name__ == "__main__":
    main()
    
