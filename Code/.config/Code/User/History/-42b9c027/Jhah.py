import argparse

import argsparse
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

parser.add_argument("-f", "--file", type=str, required=True, help="Path to the CSV file containing the time series data.")
parser.add_argument("-o", "--output-file", type=str, required=True, default="output.csv", help="Path to save the output results.")

# 1. CARGAR DATOS (Cambia 'datos.csv' y 'Tu_Columna')
df = pd.read_csv('datos.csv')
serie = df['Tu_Columna'].dropna()

# Seguro matemático: Box-Cox necesita números > 0
if serie.min() <= 0:
    serie = serie + abs(serie.min()) + 1

# ==========================================
# PASO 1: BOX-COX (ESTABILIZAR VARIANZA)
# ==========================================
serie_boxcox, lambda_optimo = stats.boxcox(serie)
print(f"--- FASE 1: VARIANZA ---")
print(f"Lambda óptimo de Box-Cox: {lambda_optimo:.4f}")

# Convertir a Pandas Series para facilitar la prueba ADF
serie_estacionaria = pd.Series(serie_boxcox)

# Si el lambda es cercano a 0, aplicamos logaritmo en lugar de la serie cruda de Box-Cox
if abs(lambda_optimo) < 0.2:
    print("Decisión: Como Lambda es cercano a 0, usaremos Logaritmo Natural.\n")
    serie_estacionaria = np.log(serie)
else:
    print("Decisión: Mantenemos la transformación cruda de Box-Cox.\n")

# ==========================================
# PASO 2: DICKEY-FULLER (ESTABILIZAR MEDIA)
# ==========================================
print(f"--- FASE 2: MEDIA (ADF) ---")
d = 0
estacionaria = False

while not estacionaria and d < 3:
    resultado_adf = adfuller(serie_estacionaria)
    p_valor = resultado_adf[1]
    
    print(f"Intento d={d} | P-valor: {p_valor:.4f}")
    
    if p_valor < 0.05:
        print(f"¡Éxito! La serie es estacionaria con d = {d}.")
        estacionaria = True
    else:
        print("La serie no es estacionaria. Aplicando una diferencia...")
        serie_estacionaria = serie_estacionaria.diff().dropna()
        d += 1


if __name__ == "__main__":
    args = parser.parse_args()