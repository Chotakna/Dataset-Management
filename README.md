# Dataset Management & ML Report Analyzer

A full-stack web application for uploading datasets, training regression models, and visualizing predictions. Built with **Flutter** (frontend) and **FastAPI** (backend).

## Features

- **Upload & Preview** — Upload CSV files, view data preview, column info, and missing values
- **Data Cleaning** — Auto-fill missing values (mean for numeric, mode for categorical)
- **Visualizations** — Scatter, Line, Bar, Histogram, Box plots, and Correlation Heatmaps
- **ML Training** — Train Linear Regression, Decision Tree, or Random Forest models with automatic feature scaling
- **Model Evaluation** — R², MAE, MSE, RMSE, Cross-Validation, Feature Importance, Actual vs Predicted & Residual plots
- **Prediction** — Make single predictions with trained models
- **History** — Browse past uploads (persisted to disk) with delete capability
- **Sample Data** — Pre-loaded datasets to explore features instantly

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Python FastAPI |
| ML | scikit-learn (Pipeline + StandardScaler) |
| Charts | Plotly |
| HTTP | package:http |

## Getting Started

### Backend

```bash
cd backend
pip install -r requirements.txt
python main.py
```

Runs on `http://localhost:8000`.

### Frontend

```bash
flutter pub get
flutter run -d chrome
```

Opens in browser at `http://localhost:5173` (or similar).

## Project Structure

```
backend/
  main.py              — FastAPI app (all API routes)
  sample_data/         — Pre-loaded CSV datasets (500+ rows each)
  uploads/             — User-uploaded files (persisted to disk)
  utils/
    model_training.py  — Model selection, training, prediction
    preprocessing.py   — Data cleaning, feature preparation
    evaluation.py      — Regression metrics, cross-validation
    visualization.py   — Plotly chart generation
    prediction.py      — Save/load models, batch predictions
lib/
  main.dart            — App entry point with bottom nav
  screens/
    home_screen.dart   — Upload, visualize, train, predict
    history_screen.dart— Recent reports + sample data browser
    profile_screen.dart— User profile (stub)
  services/
    api_service.dart   — All HTTP calls to backend
  widgets/
    chart_image.dart   — Chart image display widget
```

## API Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/upload` | Upload CSV file |
| GET | `/api/data/info` | Dataset info (shape, dtypes, missing) |
| GET | `/api/data/preview` | Preview first N rows |
| GET | `/api/data/columns` | Column names + numeric columns |
| POST | `/api/data/clean` | Fill missing values |
| GET | `/api/data/load` | Load session by session_id |
| POST | `/api/data/load-sample` | Load a sample dataset |
| GET | `/api/visualization/chart` | Chart as Plotly JSON |
| GET | `/api/visualization/chart-image` | Chart as PNG |
| GET | `/api/visualization/correlation` | Correlation heatmap |
| POST | `/api/model/train` | Train regression model |
| POST | `/api/predict` | Make a prediction |
| GET | `/api/history` | List uploaded files |
| DELETE | `/api/history/{session_id}` | Delete an uploaded file |
| GET | `/api/samples` | List sample datasets |

## Notes

- Uploads are persisted to disk in `backend/uploads/` and survive backend restarts
- Sample data in `backend/sample_data/` has 500 rows per dataset for meaningful model training
- All models use `StandardScaler` via scikit-learn Pipeline for consistent feature scaling
