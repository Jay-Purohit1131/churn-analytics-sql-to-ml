from db import run_query
import matplotlib.pyplot as plt
import seaborn as sns

sql = open("queries/03_cohort_retention.sql").read()
df = run_query(sql)
matrix = df.pivot(index='cohort_date', columns='months_since', values='pct_retained')
matrix = matrix.drop(columns=0)  

plt.figure(figsize=(14, 8))
sns.heatmap(matrix, annot=True, fmt='.1f', cmap='Blues', vmax=1)
plt.title('Olist Cohort Retention ( percentage retained by months since first order)')
plt.xlabel('Months since first order')
plt.ylabel('Cohort')
plt.tight_layout()
plt.savefig('docs/cohort_retention_heatmap.png', dpi=150)
plt.show()