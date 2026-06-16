import base64
import io
import json
import os
import uuid
from typing import Optional, List
from datetime import datetime

import pandas as pd
import numpy as np
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel

import sys
sys.path.insert(0, os.path.dirname(__file__))

from utils.preprocessing import clean_data, prepare_features, get_numeric_columns, get_data_info
from utils.model_training import select_model, get_available_models, split_data, train_model, make_predictions, get_feature_importance
from utils.evaluation import calculate_regression_metrics, cross_validate_model, get_performance_feedback
from utils.visualization import create_chart, create_correlation_heatmap, create_actual_vs_predicted, create_feature_importance_chart, create_residuals_plot, fig_to_png, fig_to_base64
from utils.prediction import save_model, load_model, prepare_batch_predictions

app = FastAPI(title="ML Report Analyzer API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

sessions: dict = {}

def get_or_create_session(session_id: str) -> dict:
    if session_id not in sessions:
        sessions[session_id] = {"df": None, "model": None, "features": None, "target": None, "filename": None}
    return sessions[session_id]

class TrainRequest(BaseModel):
    session_id: str
    target: str
    features: List[str]
    model_name: str

class PredictRequest(BaseModel):
    session_id: str
    input_data: dict

@app.get("/api/health")
def health():
    return {"status": "ok"}

@app.get("/api/models")
def list_models():
    return {"models": get_available_models()}

@app.post("/api/upload")
async def upload_file(file: UploadFile = File(...), session_id: str = Form(...)):
    if not file.filename.endswith('.csv'):
        raise HTTPException(400, "Only CSV files allowed")

    contents = await file.read()
    df = pd.read_csv(io.BytesIO(contents))

    sess = get_or_create_session(session_id)
    sess["df"] = df
    sess["filename"] = file.filename
    sess["model"] = None

    filepath = os.path.join(UPLOAD_DIR, f"{session_id}_{file.filename}")
    with open(filepath, "wb") as f:
        f.write(contents)

    info = get_data_info(df)
    return {
        "filename": file.filename,
        "rows": int(info["shape"][0]),
        "columns": int(info["shape"][1]),
        "duplicates": int(info["duplicates"]),
        "missing_values": int(sum(info["missing_values"].values())),
        "column_names": list(info["columns"])
    }

@app.get("/api/data/info")
def data_info(session_id: str):
    sess = get_or_create_session(session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")
    info = get_data_info(sess["df"])
    info["missing_values"] = {k: int(v) for k, v in info["missing_values"].items()}
    info["shape"] = [int(s) for s in info["shape"]]
    info["duplicates"] = int(info["duplicates"])
    info["dtypes"] = {k: str(v) for k, v in info["dtypes"].items()}
    return info

@app.get("/api/data/preview")
def data_preview(session_id: str, rows: int = 10):
    sess = get_or_create_session(session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")
    return {"data": json.loads(sess["df"].head(rows).to_json(orient="records"))}

@app.get("/api/data/columns")
def data_columns(session_id: str):
    sess = get_or_create_session(session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")
    df = sess["df"]
    return {
        "columns": [
            {"name": col, "dtype": str(df[col].dtype)}
            for col in df.columns
        ],
        "numeric_columns": get_numeric_columns(df)
    }

@app.post("/api/data/clean")
def clean_dataset(session_id: str):
    sess = get_or_create_session(session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")
    sess["df"] = clean_data(sess["df"])
    return {"status": "cleaned", "rows": len(sess["df"]), "columns": len(sess["df"].columns)}

@app.get("/api/data/load")
def load_session(session_id: str):
    sess = get_or_create_session(session_id)
    if sess["df"] is not None:
        info = get_data_info(sess["df"])
        return {
            "status": "loaded",
            "filename": sess["filename"],
            "rows": int(info["shape"][0]),
            "columns": int(info["shape"][1]),
        }
    for fname in os.listdir(UPLOAD_DIR):
        if fname.startswith(session_id) and fname.endswith('.csv'):
            fpath = os.path.join(UPLOAD_DIR, fname)
            sess["df"] = pd.read_csv(fpath)
            original = '_'.join(fname.split('_')[1:])
            sess["filename"] = original
            info = get_data_info(sess["df"])
            return {
                "status": "loaded",
                "filename": original,
                "rows": int(info["shape"][0]),
                "columns": int(info["shape"][1]),
            }
    raise HTTPException(404, "Session data not found on disk")

@app.post("/api/data/load-sample")
def load_sample(data: dict):
    filename = data.get("filename", "")
    SAMPLE_DIR = os.path.join(os.path.dirname(__file__), "sample_data")
    fpath = os.path.join(SAMPLE_DIR, filename)
    if not os.path.isfile(fpath):
        raise HTTPException(404, "Sample file not found")
    df = pd.read_csv(fpath)
    session_id = str(uuid.uuid4())
    sess = get_or_create_session(session_id)
    sess["df"] = df
    sess["filename"] = filename
    info = get_data_info(df)
    return {
        "session_id": session_id,
        "filename": filename,
        "rows": int(info["shape"][0]),
        "columns": int(info["shape"][1]),
    }

@app.get("/api/visualization/chart")
def chart(session_id: str, chart_type: str, x_axis: str, y_axis: str):
    sess = get_or_create_session(session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")
    df = sess["df"]
    fig = create_chart(df, chart_type, x_axis, y_axis)
    return {"plotly_json": json.loads(fig.to_json())}

@app.get("/api/visualization/correlation")
def correlation(session_id: str):
    sess = get_or_create_session(session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")
    fig = create_correlation_heatmap(sess["df"])
    return {"plotly_json": json.loads(fig.to_json())}

@app.get("/api/visualization/chart-image")
def chart_image(session_id: str, chart_type: str, x_axis: str, y_axis: str):
    sess = get_or_create_session(session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")
    fig = create_chart(sess["df"], chart_type, x_axis, y_axis)
    png = fig_to_png(fig)
    return Response(content=png, media_type="image/png")

@app.get("/api/visualization/correlation-image")
def correlation_image(session_id: str):
    sess = get_or_create_session(session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")
    fig = create_correlation_heatmap(sess["df"])
    png = fig_to_png(fig)
    return Response(content=png, media_type="image/png")

@app.post("/api/model/train")
def train(req: TrainRequest):
    sess = get_or_create_session(req.session_id)
    if sess["df"] is None:
        raise HTTPException(400, "No dataset uploaded")

    df = sess["df"]
    X, y = prepare_features(df, req.target, req.features)
    n = len(df)
    test_size = 0.3 if n < 100 else (0.25 if n < 500 else 0.2)
    X_train, X_test, y_train, y_test = split_data(X, y, test_size=test_size)

    model = select_model(req.model_name)
    model = train_model(model, X_train, y_train)

    predictions = make_predictions(model, X_test)
    metrics = calculate_regression_metrics(y_test, predictions)
    cv_results = cross_validate_model(model, X, y, cv=5, scoring='r2')
    feedback_type, feedback_message = get_performance_feedback(metrics['R2'])

    importance_df = get_feature_importance(model, X.columns.tolist())
    importance = None
    if importance_df is not None:
        importance = json.loads(importance_df.to_json(orient="records"))

    actual_vs_pred_fig = create_actual_vs_predicted(y_test, predictions)
    residuals_fig = create_residuals_plot(y_test, predictions)

    sess["model"] = model
    sess["features"] = X.columns.tolist()
    sess["target"] = req.target

    return {
        "metrics": {k: float(v) for k, v in metrics.items()},
        "cv_mean": float(cv_results["mean"]),
        "cv_std": float(cv_results["std"]),
        "cv_scores": [float(s) for s in cv_results["scores"]],
        "feedback_type": feedback_type,
        "feedback_message": feedback_message,
        "feature_importance": importance,
        "actual_vs_predicted_img": fig_to_base64(actual_vs_pred_fig),
        "residuals_img": fig_to_base64(residuals_fig),
        "test_samples": json.loads(pd.DataFrame({"actual": y_test.values, "predicted": predictions}).to_json(orient="records"))
    }

@app.post("/api/predict")
def predict(req: PredictRequest):
    sess = get_or_create_session(req.session_id)
    if sess["model"] is None:
        raise HTTPException(400, "No trained model. Train a model first.")
    if sess["features"] is None:
        raise HTTPException(400, "No feature info available.")

    input_df = pd.DataFrame([req.input_data])
    for col in sess["features"]:
        if col not in input_df.columns:
            input_df[col] = 0
    input_df = input_df[sess["features"]]

    pred = sess["model"].predict(input_df)[0]
    return {"prediction": float(pred), "target": sess["target"]}

@app.get("/api/history")
def history():
    files = []
    for fname in os.listdir(UPLOAD_DIR):
        fpath = os.path.join(UPLOAD_DIR, fname)
        if os.path.isfile(fpath) and fname.endswith('.csv'):
            sid = fname.split('_')[0]
            original = '_'.join(fname.split('_')[1:])
            files.append({
                "session_id": sid,
                "filename": original,
                "size": os.path.getsize(fpath),
                "uploaded_at": datetime.fromtimestamp(os.path.getmtime(fpath)).isoformat()
            })
    return {"files": files}

@app.delete("/api/history/{session_id}")
def delete_history(session_id: str):
    deleted = False
    for fname in os.listdir(UPLOAD_DIR):
        if fname.startswith(session_id) and fname.endswith('.csv'):
            os.remove(os.path.join(UPLOAD_DIR, fname))
            deleted = True
            break
    sessions.pop(session_id, None)
    if not deleted:
        raise HTTPException(404, "File not found")
    return {"status": "deleted"}

@app.get("/api/samples")
def list_samples():
    SAMPLE_DIR = os.path.join(os.path.dirname(__file__), "sample_data")
    os.makedirs(SAMPLE_DIR, exist_ok=True)
    files = []
    for fname in sorted(os.listdir(SAMPLE_DIR)):
        fpath = os.path.join(SAMPLE_DIR, fname)
        if os.path.isfile(fpath) and fname.endswith('.csv'):
            files.append({
                "filename": fname,
                "size": os.path.getsize(fpath),
                "description": fname.replace('.csv', '').replace('_', ' ').title()
            })
    return {"files": files}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
