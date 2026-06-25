# TaianLux Approch:
# This script is not designed to handle large volumes of data. 
# The method used progressively loads all the specified data series into RAM and then writes them to the indicated files. 
# Although trivial, it's worth mentioning that for certain programming environments, to have the libraries working, 
# it will be necessary to create a virtual environment with the command `python -m venv` and then install the necessary libraries using `pip`.
import pandas as pd
from fredapi import Fred
import datetime
from pathlib import Path
import sys
import json

# --- INITIALIZE FRED CONNECTION ---
API_KEY = "8e822e32166531295e505b049837bd76"

try:
    fred = Fred(api_key=API_KEY)
except Exception as e:
    print(f"[-] Error connecting to FRED: {e}")
    sys.exit(1)

# Dates for data extraction
# --- Quarterly data from 1995 to 2025 ---
start_date_q = datetime.datetime(1995, 1, 1)
end_date_q = datetime.datetime(2025, 12, 31)

# --- Monthly data from 2005 to 2025 ---
start_date_m = datetime.datetime(2005, 1, 1)
end_date_m = datetime.datetime(2025, 12, 31)

# -- Extracting data function ---
def extract_data(ticker, start_date, end_date, column_name):
    raw_data = fred.get_series(ticker, observation_start=start_date, observation_end=end_date)
    request_data = pd.DataFrame(raw_data, columns=[column_name])
    return request_data

# -- Extracting metadata function --
def extract_metadata(tickers_list):
    metadata_dict = {}
    for ticker in tickers_list:
        try:
            info = fred.get_series_info(ticker)
            metadata_dict[ticker] = {
                "titulo_oficial": info.get('title', 'N/A'),
                "unidades": info.get('units', 'N/A'),
                "frecuencia": info.get('frequency', 'N/A'),
                "ajuste_estacional": info.get('seasonal_adjustment', 'N/A'),
                "notas": info.get('notes', 'N/A')
            }
        except Exception as e:
            print(f"[-] An error occurred while extracting metadata for {ticker}: {e}")
    return metadata_dict

if __name__ == "__main__":
    print("[*] Starting data extraction using fredapi...")
    
    # DATA EXTRACTION
    try:
        # -- Extracting GDP data --
        quarterly_gdp = extract_data('GDPC1', start_date_q, end_date_q, "PBI_Trimestral") 
        monthly_gdp = extract_data('CFNAI', start_date_m, end_date_m, "PBI_Mensual") 

        # -- Extracting consumption data --
        quarterly_consumption = extract_data('PCECC96', start_date_q, end_date_q, "Consumo_Trimestral") 
        monthly_consumption = extract_data('PCEC96', start_date_m, end_date_m, "Consumo_Mensual") 
        print("[+] Data extraction completed successfully.\n")
        used_tickers = ['GDPC1', 'CFNAI', 'PCECC96', 'PCEC96']
        metadata = extract_metadata(used_tickers)
        print("[+] Metadata extraction completed successfully.\n")
    except Exception as e:
        print(f"[-] Fatal Error in extraction process: {e}")
        sys.exit(1) 

    # DATA STORAGE
    try:
        # -- Saving data to CSV files in 'data' folder --
        path = Path("data")
        path.mkdir(exist_ok=True)
        
        # By default, fredapi index has no name. Assigning 'DATE' for a clean CSV.
        quarterly_gdp.index.name = 'DATE'
        monthly_gdp.index.name = 'DATE'
        quarterly_consumption.index.name = 'DATE'
        monthly_consumption.index.name = 'DATE'

        quarterly_gdp.to_csv(path / 'quarterly_gdp.csv')
        monthly_gdp.to_csv(path / 'monthly_gdp.csv')
        quarterly_consumption.to_csv(path / 'quarterly_consumption.csv')
        monthly_consumption.to_csv(path / 'monthly_consumption.csv')        
        print("[+] All data stored in CSV files successfully.")
        
        with open(path / 'metadata.json', 'w', encoding='utf-8') as f:
            json.dump(metadata, f, ensure_ascii=False, indent=4)
        print("[+] Metadata stored in JSON file successfully.")

    except Exception as e:
        print(f"[-] An error occurred while saving the data to CSV files: {e}")
