from db import run_query
from sklearn.model_selection import train_test_split

def get_train_test():
    df = run_query("SELECT * FROM feature_view")
    df['has_review'] = df['avg_review_score'].notna().astype(int)
    df['avg_review_score'] = df['avg_review_score'].fillna(df['avg_review_score'].median())

    X = df.drop(columns=['customer_unique_id', 'is_churned','recency'])
    y = df['is_churned']

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    return X_train, X_test, y_train, y_test


if __name__ == "__main__":
    X_train, X_test, y_train, y_test = get_train_test()
    print(X_train.shape, X_test.shape)
    print(y_train.value_counts(normalize=True))

# Class balance: 70.8% churned / 29.2% active. Moderate imbalance.
# -> use class_weight='balanced' when training; evaluate with ROC-AUC and
#    precision/recall, NOT raw accuracy (a "predict churned always" baseline
#    already scores ~71%).