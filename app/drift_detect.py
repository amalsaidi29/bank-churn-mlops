import matplotlib
matplotlib.use('Agg')

import pandas as pd
import numpy as np
from scipy.stats import ks_2samp
import json
import os
from datetime import datetime

def detect_drift(reference_file, production_file, threshold=0.05, output_dir="drift_reports"):
    os.makedirs(output_dir, exist_ok=True)
    
    ref = pd.read_csv(reference_file)
    prod = pd.read_csv(production_file)
    
    results = {}
    
    for col in ref.columns:
        if col != 'Exited' and col in prod.columns:
            stat, p_value = ks_2samp(ref[col].dropna(), prod[col].dropna())
            
            results[col] = {
                'p_value': float(p_value),
                'statistic': float(stat),
                'drift_detected': bool(p_value < threshold),
                'type': 'numerical'
            }
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_path = f'{output_dir}/drift_{timestamp}.json'
    
    with open(report_path, 'w') as f:
        json.dump(results, f, indent=2)
    
    return results
