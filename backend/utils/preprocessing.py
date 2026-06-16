"""
Data preprocessing utilities for machine learning pipeline.
Handles data loading, cleaning, and feature engineering.
"""

import pandas as pd
import numpy as np


def load_data(uploaded_file=None, filepath=None):
    """
    Load CSV data from file or uploaded file.
    
    Args:
        uploaded_file: Streamlit uploaded file object
        filepath: Path to CSV file
        
    Returns:
        pd.DataFrame: Loaded dataset
    """
    if uploaded_file is not None:
        return pd.read_csv(uploaded_file)
    elif filepath is not None:
        return pd.read_csv(filepath)
    else:
        raise ValueError("Either uploaded_file or filepath must be provided")


def clean_data(df):
    """
    Clean dataset by filling missing values.
    
    Args:
        df: Input dataframe
        
    Returns:
        pd.DataFrame: Cleaned dataframe
    """
    df_cleaned = df.copy()
    
    # Fill missing numeric values with mean
    numeric_cols = df_cleaned.select_dtypes(include=['float64', 'int64']).columns
    for col in numeric_cols:
        if df_cleaned[col].isnull().sum() > 0:
            df_cleaned[col].fillna(df_cleaned[col].mean(), inplace=True)
    
    # Fill missing categorical values with mode
    categorical_cols = df_cleaned.select_dtypes(include=['object']).columns
    for col in categorical_cols:
        if df_cleaned[col].isnull().sum() > 0:
            df_cleaned[col].fillna(df_cleaned[col].mode()[0], inplace=True)
    
    return df_cleaned


def prepare_features(df, target_col, selected_features):
    """
    Prepare features and target for model training.
    
    Args:
        df: Input dataframe
        target_col: Target column name
        selected_features: List of feature column names
        
    Returns:
        tuple: (X, y) feature matrix and target vector
    """
    X = df[selected_features].copy()
    X = pd.get_dummies(X)
    X = X.fillna(0)
    
    y = df[target_col]
    
    return X, y


def get_numeric_columns(df):
    """
    Get numeric columns from dataframe.
    
    Args:
        df: Input dataframe
        
    Returns:
        list: Numeric column names
    """
    return df.select_dtypes(include=['float64', 'int64']).columns.tolist()


def get_data_info(df):
    """
    Get information about dataset.
    
    Args:
        df: Input dataframe
        
    Returns:
        dict: Dataset information
    """
    info = {
        'shape': df.shape,
        'columns': df.columns.tolist(),
        'dtypes': df.dtypes.to_dict(),
        'missing_values': df.isnull().sum().to_dict(),
        'duplicates': df.duplicated().sum()
    }
    return info
