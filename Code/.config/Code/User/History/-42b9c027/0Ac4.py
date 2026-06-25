import argparse
import pandas as pd
import numpy as np
from scipy import stats
from statsmodels.tsa.stattools import adfuller

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
    def __init__(self, args):
        self.file_path = args.file
        self.output_file = args.output_file

    def load_data(self):
        df = pd.read_csv(self.file_path)
        return df

    def boxcox_transform(self, serie):
        if serie.min() <= 0:
            serie = serie + abs(serie.min()) + 1
        print("[+] Applying Box-Cox transformation...")
        transformed_serie, optimal_lambda = stats.boxcox(serie)
        print(f"[+] Box-Cox lambda (λ): {optimal_lambda:.4f}")
        return transformed_serie, optimal_lambda

    def adf_test(self, serie):
        d = 0
        stationary = False
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
        return d, serie
    
    @staticmethod
    def save_output(output_file, LOG_TRANSFORMED_SERIE = "log.txt", optimal_lambda, d, stationary_serie):
        with open(LOG_TRANSFORMED_SERIE, 'w') as f:
            f.write(f"Optimal Lambda (λ): {optimal_lambda:.4f}\n")
            f.write(f"Order of Differencing (d): {d}\n")
        print(f"[+] Results saved to {output_file}")

# Main flow
if __name__ == "__main__":
    args = parser.parse_args()
    core_transformer= EconometricTransformer(args)
    load_serie = EconometricTransformer.load_data(core_transformer)
    transformed_serie, optimal_lambda = EconometricTransformer.boxcox_transform(load_serie)
    d, stationary_serie = EconometricTransformer.adf_test(transformed_serie)
    EconometricTransformer.save_output(args.output_file, optimal_lambda, d, stationary_serie)