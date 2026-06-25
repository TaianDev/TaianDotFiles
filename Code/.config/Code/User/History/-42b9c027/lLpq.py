import argparse
import pandas as pd
import numpy as np
from scipy import stats
from statsmodels.tsa.stattools import adfuller
from pathlib import Path
import sys

# Argument parser
parser = argparse.ArgumentParser(
    prog = "Ld_identifier",
    description="This program identifies the order of differencing for time series data in the context of Box-Jenkins methodology.\
    Uses for get the lambda(\u03bb) of Box-Cox transformation and the order of differencing (d) for stationarity.\
    The program receives a CSV file with the time series data and a column name, and transforms it accordingly, if desired.",)

parser.add_argument(
    "-f", 
    "--file", 
    type=str, 
    required=True, 
    help="Path to the CSV file containing the time series data."
    )

parser.add_argument(
    "-o", 
    "--output-file", 
    type=str, 
    required=False, 
    default= None, 
    help="Path to save the output results, if desired."
    )

parser.add_argument(
    "-s", 
    "--skip-boxcox", 
    action="store_true", # Si el usuario pone -s, esto será True. Si no, False.
    help="Skips the Box-Cox transformation. Highly recommended if data is already in rates or percentages."
)

# Core class "transformer"
class EconometricTransformer:
    #Constructor
    def __init__(self, args):
        self.file_path = args.file
        self.output_file = args.output_file

    # Data loader
    def load_data(self):
        try:
            df = pd.read_csv(self.file_path)
        except FileNotFoundError:
            print(f"Error: File not found - {self.file_path}")
            sys.exit(1)
        except pd.errors.EmptyDataError:
            print(f"Error: Empty file - {self.file_path}")
            sys.exit(1)
        return df

    # Box-Cox transformation
    def boxcox_transform(self, serie, skip_requested=False):
        if skip_requested:
            print("[+] Skipping Box-Cox transformation explicitly requested.")
            return serie, 1.0  # Lambda 1.0 significa "sin transformación"

        # 2. Autodetección: ¿Son tasas o porcentajes?
        # Si el máximo es un número relativamente pequeño (ej. menor a 50) y tiene valores negativos
        if serie.max() < 50 and serie.min() < 0:
            print("[!] Data appears to be rates or percentages (small magnitudes and negative values).")
            print("[+] Auto-skipping Box-Cox to preserve economic interpretation.")
            return serie, 1.0
        
        try:
            if serie.min() <= 0:
                serie = serie + abs(serie.min()) + 1
            print("[+] Applying Box-Cox transformation...")
            transformed_serie, optimal_lambda = stats.boxcox(serie)
            transformed_serie = pd.Series(transformed_serie, index=serie.index)
            print(f"[+] Box-Cox lambda (λ): {optimal_lambda:.4f}")
            return transformed_serie, optimal_lambda
        except Exception as e:
            print(f"[!] Error ocurring during Box-Cox transformation: {e}")
            sys.exit(1)

    # Augmented Dickey-Fuller test
    def adf_test(self, serie):
        d = 0
        stationary = False
        try:
            while not stationary and d < 3:
                adf_result = adfuller(serie)
                p_valor = adf_result[1]

                print(f"[!] Attempt d={d} | P-valor: {p_valor:.4f}")
                
                if p_valor < 0.05:
                    print(f"[+] Success! The series is stationary with d = {d}.")
                    stationary = True
                else:
                    print(f"[!] The series is not stationary. Applying a difference...")
                    serie = serie.diff().dropna()
                    d += 1
        except Exception as e:
            print(f"[!] Error ocurring during ADF test: {e}")
            sys.exit(1)
        return d, serie
    
    #Satatic method to save output results, including optimal lambda, order of differencing, and the stationary series to a CSV file. 
    # It does not overwrite the original data series
    @staticmethod
    def save_output( optimal_lambda, d, stationary_serie, output_file, LOG_TRANSFORMED_SERIE = "log.txt"):
  
        #Log_saver
        with open(LOG_TRANSFORMED_SERIE, 'w') as f:
            f.write(f"Optimal Lambda (λ): {optimal_lambda:.4f}\n")
            f.write(f"Order of Differencing (d): {d}\n")
        print(f"[+] Results of lambda and differencing saved to {output_file}")

        # Save the stationary series to a CSV file
        try:
            stationary_serie.to_csv(output_file, index=False)
            print(f"[+] Stationary series saved to {output_file}")
        except Exception as e:
            print(f"[!] Error ocurring while saving the stationary series: {e}")
            sys.exit(1)

# Main flow
if __name__ == "__main__":
    # Create a parser and parse the arguments
    args = parser.parse_args()
    # Initialize the core transformer and execute the main steps
    core_transformer= EconometricTransformer(args)

    ## 1) Load the data series from the specified CSV file
    load_serie = core_transformer.load_data()

    ## 2) Check if the loaded data is a single column, if not, ask the user to specify the column name
    if load_serie.shape[1] > 1:
        print(f"[!] The loaded data contains multiple columns: {load_serie.columns.tolist()}")
        column_name = input("Please specify the column name to be transformed: ")
        if column_name not in load_serie.columns:
            print(f"Error: Column '{column_name}' not found in the data.")
            sys.exit(1)
        load_serie = load_serie[column_name]
    else:
        load_serie = load_serie.iloc[:, 0]  # Take the first column if only one is present

    ## 3) Apply Box-Cox transformation to the loaded series and obtain the optimal lambda
    #transformed_serie, optimal_lambda = core_transformer.boxcox_transform(load_serie)
    ## 3) Apply Box-Cox (or skip it intelligently)
    transformed_serie, optimal_lambda = core_transformer.boxcox_transform(load_serie, skip_requested=args.skip_boxcox)

    ## 4) Perform the Augmented Dickey-Fuller test to determine the order of differencing (d) needed for stationarity, and obtain the stationary series
    d, stationary_serie = core_transformer.adf_test(transformed_serie)

    ## 5) If an output file path is provided, save the optimal lambda, order of differencing, and the stationary series to a CSV file
    if args.output_file:
        core_transformer.save_output(optimal_lambda, d, stationary_serie, args.output_file)