"""
Model evaluation utilities for assessing model performance.
Calculates metrics and cross-validation scores.
"""

import numpy as np
import pandas as pd
from sklearn.metrics import (
    mean_absolute_error,
    mean_squared_error,
    r2_score,
    accuracy_score,
    precision_score,
    recall_score,
    f1_score
)
from sklearn.model_selection import cross_val_score


def calculate_regression_metrics(y_true, y_pred):
    """
    Calculate regression evaluation metrics.
    
    Args:
        y_true: Actual values
        y_pred: Predicted values
        
    Returns:
        dict: Dictionary of metrics
    """
    mae = mean_absolute_error(y_true, y_pred)
    mse = mean_squared_error(y_true, y_pred)
    rmse = np.sqrt(mse)
    r2 = r2_score(y_true, y_pred)
    
    return {
        'MAE': mae,
        'MSE': mse,
        'RMSE': rmse,
        'R2': r2
    }


def calculate_classification_metrics(y_true, y_pred):
    """
    Calculate classification evaluation metrics.
    
    Args:
        y_true: Actual values
        y_pred: Predicted values
        
    Returns:
        dict: Dictionary of metrics
    """
    accuracy = accuracy_score(y_true, y_pred)
    precision = precision_score(y_true, y_pred, average='weighted', zero_division=0)
    recall = recall_score(y_true, y_pred, average='weighted', zero_division=0)
    f1 = f1_score(y_true, y_pred, average='weighted', zero_division=0)
    
    return {
        'Accuracy': accuracy,
        'Precision': precision,
        'Recall': recall,
        'F1 Score': f1
    }


def cross_validate_model(model, X, y, cv=5, scoring='r2'):
    """
    Perform cross-validation on model.
    
    Args:
        model: Model to validate
        X: Features
        y: Target
        cv: Number of cross-validation folds
        scoring: Scoring metric
        
    Returns:
        dict: Cross-validation results
    """
    scores = cross_val_score(model, X, y, cv=cv, scoring=scoring)
    
    return {
        'scores': scores,
        'mean': scores.mean(),
        'std': scores.std()
    }


def get_performance_feedback(r2_score):
    """
    Get qualitative feedback based on R² score.
    
    Args:
        r2_score: R² score
        
    Returns:
        tuple: (feedback_type, message)
    """
    if r2_score > 0.9:
        return ('success', 'Excellent model performance! 🎉')
    elif r2_score > 0.7:
        return ('info', 'Good model performance! 👍')
    elif r2_score > 0.5:
        return ('warning', 'Moderate model performance. Consider improving features or trying different models.')
    else:
        return ('error', 'Poor model performance. Try feature engineering or different models.')


def create_evaluation_report(y_true, y_pred, model_name):
    """
    Create comprehensive evaluation report.
    
    Args:
        y_true: Actual values
        y_pred: Predicted values
        model_name: Name of model
        
    Returns:
        dict: Evaluation report
    """
    metrics = calculate_regression_metrics(y_true, y_pred)
    
    report = {
        'model': model_name,
        'metrics': metrics,
        'feedback_type': get_performance_feedback(metrics['R2'])[0],
        'feedback_message': get_performance_feedback(metrics['R2'])[1]
    }
    
    return report


def save_evaluation_report(report, filepath):
    """
    Save evaluation report to JSON.
    
    Args:
        report: Report dictionary
        filepath: Path to save report
    """
    import json
    
    with open(filepath, 'w') as f:
        json.dump(report, f, indent=4)
