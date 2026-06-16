"""
Visualization utilities for interactive charts and plots.
Handles creation of various chart types using Plotly.
"""

import base64
import io
import pandas as pd
import plotly.express as px
import plotly.io as pio


def create_chart(df, chart_type, x_axis, y_axis):
    """
    Create interactive chart based on chart type.
    
    Args:
        df: Input dataframe
        chart_type: Type of chart (Scatter, Line, Bar, Histogram, Box Plot)
        x_axis: X-axis column name
        y_axis: Y-axis column name
        
    Returns:
        plotly.graph_objs.Figure: Chart figure
    """
    if chart_type == "Scatter":
        fig = px.scatter(
            df,
            x=x_axis,
            y=y_axis,
            title=f"{y_axis} vs {x_axis}",
            height=600,
            width=900
        )
    elif chart_type == "Line":
        fig = px.line(
            df, 
            x=x_axis, 
            y=y_axis, 
            title=f"{y_axis} vs {x_axis}", 
            height=600, 
            width=900,
            markers=True
        )
        fig.update_traces(
            line=dict(width=3),
            marker=dict(size=8, symbol='circle')
        )
    elif chart_type == "Bar":
        fig = px.bar(df, x=x_axis, y=y_axis, title=f"{y_axis} vs {x_axis}", height=600, width=900)
    elif chart_type == "Histogram":
        fig = px.histogram(df, x=x_axis, title=f"Distribution of {x_axis}", height=600, width=900)
    else:  # Box Plot
        fig = px.box(df, x=x_axis, y=y_axis, title=f"Box Plot: {y_axis} by {x_axis}", height=600, width=900)
    
    fig.update_layout(
        template="plotly_white",
        font=dict(size=12),
        margin=dict(l=80, r=120, t=100, b=80),
        hovermode="closest",
        legend=dict(
            x=1.02,
            y=1,
            bgcolor="rgba(255, 255, 255, 0.8)",
            bordercolor="LightGray",
            borderwidth=1,
            font=dict(size=11)
        ),
        showlegend=True
    )
    fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    fig.update_yaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    
    return fig


def create_correlation_heatmap(df):
    """
    Create correlation heatmap for numeric columns.
    
    Args:
        df: Input dataframe
        
    Returns:
        plotly.graph_objs.Figure: Heatmap figure
    """
    corr = df.corr(numeric_only=True)
    
    fig = px.imshow(
        corr,
        text_auto=True,
        aspect="auto",
        title="Feature Correlation Heatmap",
        color_continuous_scale="RdBu",
        height=700,
        width=900
    )
    
    fig.update_layout(
        template="plotly_white",
        font=dict(size=11),
        margin=dict(l=100, r=50, t=100, b=100)
    )
    
    return fig


def create_actual_vs_predicted(y_test, predictions):
    """
    Create scatter plot of actual vs predicted values.
    
    Args:
        y_test: Actual test values
        predictions: Model predictions
        
    Returns:
        plotly.graph_objs.Figure: Scatter plot figure
    """
    fig = px.scatter(
        x=y_test.values if isinstance(y_test, pd.Series) else y_test,
        y=predictions,
        labels={
            "x": "Actual Values",
            "y": "Predicted Values"
        },
        title="Actual vs Predicted Values",
        height=600,
        width=900
    )
    
    fig.update_layout(
        template="plotly_white",
        font=dict(size=12),
        margin=dict(l=80, r=120, t=100, b=80),
        hovermode="closest",
        legend=dict(
            x=1.02,
            y=1,
            bgcolor="rgba(255, 255, 255, 0.8)",
            bordercolor="LightGray",
            borderwidth=1,
            font=dict(size=11)
        ),
        showlegend=True
    )
    fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    fig.update_yaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    
    return fig


def create_feature_importance_chart(importance_df):
    """
    Create bar chart for feature importance.
    
    Args:
        importance_df: DataFrame with columns ['Feature', 'Importance']
        
    Returns:
        plotly.graph_objs.Figure: Bar chart figure
    """
    importance_sorted = importance_df.sort_values(
        by='Importance',
        ascending=False
    )
    
    fig = px.bar(
        importance_sorted.head(10),
        x='Importance',
        y='Feature',
        orientation='h',
        title="Top 10 Important Features",
        height=500,
        width=900
    )
    
    fig.update_layout(
        template="plotly_white",
        font=dict(size=12),
        margin=dict(l=150, r=50, t=100, b=80),
        hovermode="closest",
        showlegend=False
    )
    fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    
    return fig


def fig_to_png(fig):
    buf = io.BytesIO(pio.to_image(fig, format='png'))
    return buf.getvalue()


def fig_to_base64(fig):
    return base64.b64encode(fig_to_png(fig)).decode('utf-8')


def create_residuals_plot(y_test, predictions):
    """
    Create residuals plot.
    
    Args:
        y_test: Actual test values
        predictions: Model predictions
        
    Returns:
        plotly.graph_objs.Figure: Residuals plot figure
    """
    residuals = y_test.values - predictions
    
    fig = px.scatter(
        x=predictions,
        y=residuals,
        labels={
            "x": "Predicted Values",
            "y": "Residuals"
        },
        title="Residuals Plot",
        height=600,
        width=900
    )
    
    # Add a horizontal line at y=0
    fig.add_hline(y=0, line_dash="dash", line_color="red", line_width=2)
    
    fig.update_layout(
        template="plotly_white",
        font=dict(size=12),
        margin=dict(l=80, r=120, t=100, b=80),
        hovermode="closest",
        legend=dict(
            x=1.02,
            y=1,
            bgcolor="rgba(255, 255, 255, 0.8)",
            bordercolor="LightGray",
            borderwidth=1,
            font=dict(size=11)
        ),
        showlegend=True
    )
    fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    fig.update_yaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    
    return fig


def create_multi_column_chart(df, chart_type, x_axis, y_columns):
    """
    Create interactive chart with multiple target variables.
    
    Args:
        df: Input dataframe
        chart_type: Type of chart (Line, Scatter, Bar)
        x_axis: X-axis column name
        y_columns: List of Y-axis column names or single column name
        
    Returns:
        plotly.graph_objs.Figure: Chart figure with legend
    """
    # Convert single column to list
    if isinstance(y_columns, str):
        y_columns = [y_columns]
    
    # Use px.line with color parameter for multiple series
    if chart_type == "Line":
        fig = px.line(
            df, 
            x=x_axis, 
            y=y_columns,
            title=f"Multiple Variables vs {x_axis}",
            height=600, 
            width=900,
            markers=True
        )
        fig.update_traces(
            line=dict(width=3),
            marker=dict(size=8, symbol='circle')
        )
    elif chart_type == "Scatter":
        fig = px.scatter(
            df,
            x=x_axis,
            y=y_columns,
            title=f"Multiple Variables vs {x_axis}",
            height=600,
            width=900
        )
    else:  # Bar
        fig = px.bar(
            df, 
            x=x_axis, 
            y=y_columns,
            title=f"Multiple Variables vs {x_axis}",
            height=600,
            width=900,
            barmode='group'
        )
    
    fig.update_layout(
        template="plotly_white",
        font=dict(size=12),
        margin=dict(l=80, r=120, t=100, b=80),
        hovermode="closest",
        legend=dict(
            x=1.02,
            y=1,
            bgcolor="rgba(255, 255, 255, 0.8)",
            bordercolor="LightGray",
            borderwidth=1,
            font=dict(size=11),
            title="Variables"
        ),
        showlegend=True
    )
    fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    fig.update_yaxes(showgrid=True, gridwidth=1, gridcolor='LightGray')
    
    return fig
