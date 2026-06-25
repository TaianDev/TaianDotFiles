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
    default="output.csv", 
    help="Path to save the output results."
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
    def boxcox_transform(self, serie):
        try:
            if serie.min() <= 0:
                serie = serie + abs(serie.min()) + 1
            print("[+] Applying Box-Cox transformation...")
            transformed_serie, optimal_lambda = stats.boxcox(serie)
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
        stationary_serie.to_csv(output_file, index=False)
        print(f"[+] Stationary series saved to {output_file}")

# Main flow
if __name__ == "__main__":
    args = parser.parse_args()
    core_transformer= EconometricTransformer(args)
    load_serie = EconometricTransformer.load_data(core_transformer)
    transformed_serie, optimal_lambda = EconometricTransformer.boxcox_transform(load_serie)
    d, stationary_serie = EconometricTransformer.adf_test(transformed_serie)
    EconometricTransformer.save_output(optimal_lambda, d, stationary_serie, args.output_file)