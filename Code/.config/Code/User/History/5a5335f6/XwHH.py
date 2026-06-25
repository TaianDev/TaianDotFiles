import pandas as pd
import pandas_datareader.data as web
import datetime
import matplotlib.pyplot as plt
from pathlib import Path

# Dates for data extraction
# --- Quarterly data from 1995 to 2025 ---
start_date_q = datetime.datetime(1995, 1, 1)
end_date_q = datetime.datetime(2025, 12, 31)

# --- Monthly data from 2005 to 2025 ---
start_date_m = datetime.datetime(2005, 1, 1)
end_date_m = datetime.datetime(2025, 12, 31)

# -- Extracting data function ---
def extract_data(ticker, database, start_date, end_date, column_name):
    request_data = web.DataReader(ticker, database, start_date, end_date)
    request_data.rename(columns={ticker: column_name}, inplace=True)

    return request_data

if __name__ == "__main__":
    try:
        # -- Extracting GDP (or PBI) data --
        quarterly_gdp = extract_data('GDPC1', 'fred', start_date_q, end_date_q, "PBI_Trimestral") # Quarterly data for Real GDP
        monthly_gdp = extract_data('CFNAI', 'fred', start_date_m, end_date_m, "PBI_Mensual") # Monthly data for Real GDP

        # -- Extracting consuption (or consumo) data --
        quarterly_consumption = extract_data('PCECC96', 'fred', start_date_q, end_date_q, "Consumo_Trimestral") # Quarterly data for Real Consumption
        monthly_consumption = extract_data('PCEC96', 'fred', start_date_m, end_date_m, "Consumo_Mensual") # Monthly data for Real Consumption
    except Exception as e:
        print(f"An error occurred in the data extraction process: {e}")

    print("[+] Data extraction completed successfully.")
    print("[+] The data is stored in CSV files according to its type")
    
    try:
        # -- Saving data to CSV files in 'data' folder --
        path = Path("data")
        path.mkdir(exist_ok=True)
        quarterly_gdp.to_csv(path / 'quarterly_gdp.csv')
        monthly_gdp.to_csv(path / 'monthly_gdp.csv')
        quarterly_consumption.to_csv(path / 'quarterly_consumption.csv')
        monthly_consumption.to_csv(path / 'monthly_consumption.csv')
    except Exception as e:
        print(f"An error occurred while saving the data to CSV files: {e}")
