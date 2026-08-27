from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import roc_auc_score, classification_report, confusion_matrix
import pandas as pd
import joblib
import os
from pipeline import get_train_test

os.makedirs("models", exist_ok=True)

X_train, X_test, y_train, y_test = get_train_test()

# Scale for logistic regression (fit on train only, apply to test)
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled  = scaler.transform(X_test)

# Logistic regression trains on SCALED data
logreg = LogisticRegression(class_weight='balanced', max_iter=1000)
logreg.fit(X_train_scaled, y_train)

# Random forest trains on RAW data (trees are scale-invariant)
rf = RandomForestClassifier(class_weight='balanced', random_state=42, n_estimators=100)
rf.fit(X_train, y_train)

# Evaluate — each model paired with the matching test set
for name, model, Xte in [("LogReg", logreg, X_test_scaled), ("RandomForest", rf, X_test)]:
    preds = model.predict(Xte)
    proba = model.predict_proba(Xte)[:, 1]     # probability of churn
    print(f"\n=== {name} ===")
    print("ROC-AUC:", round(roc_auc_score(y_test, proba), 3))
    print(confusion_matrix(y_test, preds))
    print(classification_report(y_test, preds))

# Logistic regression: coefficients (signed — direction matters, comparable since scaled)
coefs = pd.Series(logreg.coef_[0], index=X_train.columns).sort_values()
print("\nLogReg coefficients:\n", coefs)

# Random forest: importances (magnitude only)
importances = pd.Series(rf.feature_importances_, index=X_train.columns).sort_values(ascending=False)
print("\nRF importances:\n", importances)

# Save the trained model + scaler (scaler needed to score new data the same way)
joblib.dump(rf, "models/churn_model.pkl")
joblib.dump(scaler, "models/scaler.pkl")
print("\nSaved model and scaler to models/")