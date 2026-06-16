from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline


def _model_for_name(model_name):
    if model_name == "Linear Regression":
        return ("lr", LinearRegression())
    elif model_name == "Decision Tree":
        return ("dt", DecisionTreeRegressor(random_state=42, max_depth=5, min_samples_leaf=5))
    elif model_name == "Random Forest":
        return ("rf", RandomForestRegressor(n_estimators=100, random_state=42, max_depth=8, min_samples_leaf=3))
    else:
        raise ValueError(f"Model '{model_name}' not recognized")


def select_model(model_name):
    steps = [("scaler", StandardScaler())]
    name, estimator = _model_for_name(model_name)
    steps.append((name, estimator))
    return Pipeline(steps)


def get_available_models():
    return ["Linear Regression", "Decision Tree", "Random Forest"]


def split_data(X, y, test_size=0.2, random_state=42):
    return train_test_split(X, y, test_size=test_size, random_state=random_state)


def train_model(model, X_train, y_train):
    model.fit(X_train, y_train)
    return model


def make_predictions(model, X):
    return model.predict(X)


def get_feature_importance(model, feature_names):
    import pandas as pd

    estimator = model.steps[-1][1] if hasattr(model, 'steps') else model

    if hasattr(estimator, 'feature_importances_'):
        importance_df = pd.DataFrame({
            'Feature': feature_names,
            'Importance': estimator.feature_importances_
        })
        return importance_df.sort_values(by='Importance', ascending=False)
    return None
