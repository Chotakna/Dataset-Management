"""
Prediction utilities for making new predictions with trained models.
Handles data preparation and prediction formatting.
"""

import pandas as pd
import joblib
import json
import os


def save_model(model, filepath):
    """
    Save trained model to disk.
    
    Args:
        model: Trained model
        filepath: Path to save model
    """
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    joblib.dump(model, filepath)


def load_model(filepath):
    """
    Load trained model from disk.
    
    Args:
        filepath: Path to model file
        
    Returns:
        sklearn model: Loaded model
    """
    return joblib.load(filepath)


def save_metrics(metrics, filepath):
    """
    Save model metrics to JSON.
    
    Args:
        metrics: Metrics dictionary
        filepath: Path to save metrics
    """
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w') as f:
        json.dump(metrics, f, indent=4)


def load_metrics(filepath):
    """
    Load model metrics from JSON.
    
    Args:
        filepath: Path to metrics file
        
    Returns:
        dict: Metrics dictionary
    """
    with open(filepath, 'r') as f:
        return json.load(f)


def prepare_single_prediction(input_dict, feature_columns):
    """
    Prepare single input for prediction.
    
    Args:
        input_dict: Dictionary of input values
        feature_columns: List of feature column names
        
    Returns:
        pd.DataFrame: Prepared input dataframe
    """
    input_df = pd.DataFrame([input_dict])
    
    # Ensure all feature columns exist
    for col in feature_columns:
        if col not in input_df.columns:
            input_df[col] = 0
    
    # Reorder columns to match training data
    input_df = input_df[feature_columns]
    
    return input_df


def predict_single(model, input_df):
    """
    Make single prediction.
    
    Args:
        model: Trained model
        input_df: Prepared input dataframe
        
    Returns:
        float: Prediction value
    """
    prediction = model.predict(input_df)
    return prediction[0]


def prepare_batch_predictions(results_df, filepath=None):
    """
    Prepare prediction results for download.
    
    Args:
        results_df: DataFrame with Actual and Predicted columns
        filepath: Optional path to save CSV
        
    Returns:
        str: CSV string
    """
    csv = results_df.to_csv(index=False)
    
    if filepath:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        results_df.to_csv(filepath, index=False)
    
    return csv


def create_prediction_summary(y_true, y_pred):
    """
    Create summary of predictions.
    
    Args:
        y_true: Actual values
        y_pred: Predicted values
        
    Returns:
        dict: Prediction summary
    """
    errors = abs(y_true.values - y_pred) if isinstance(y_true, pd.Series) else abs(y_true - y_pred)
    
    summary = {
        'total_predictions': len(y_pred),
        'mean_error': float(errors.mean()),
        'max_error': float(errors.max()),
        'min_error': float(errors.min()),
        'std_error': float(errors.std())
    }
    
    return summary
