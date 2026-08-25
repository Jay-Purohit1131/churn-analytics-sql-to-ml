# Churn Definition

## Context
Olist is a non-contractual e-commerce marketplace: customers don't subscribe or
"cancel", they simply stop purchasing. There is no built-in churn label, so churn
must be defined explicitly. This document records that definition and the reasoning
behind it, so every downstream step (cohorts, RFM, the churn model) uses one
consistent rule.

## Key finding that shapes the definition
Exploratory analysis showed that only **~3.1%** of customers ever place more than one
order (2,997 repeat customers out of 96,096 total). The overwhelming majority are
one-time buyers.

**Implication:** if churn is defined as "has not purchased again", ~97% of customers
are churned by construction. This makes an all-customer churn model trivial and
imbalanced. The definition and modelling scope below are chosen with this reality in
mind.

## Definitions

**Customer.** A customer is identified by `customer_unique_id` (not `customer_id`,
which is unique per order). Only orders with `order_status = 'delivered'` count as
real purchases; cancelled/unavailable orders are excluded.

**Snapshot date.** The reference "today" for measuring inactivity is the latest
purchase date in the dataset: **max(order_purchase_timestamp) ≈ 2018-10-17**. All
recency is measured relative to this fixed point.

**Churn rule.** A customer is **churned** if the number of days between their most
recent delivered order and the snapshot date exceeds **N = 180 days**. Otherwise they
are **active**.

- churned:  (snapshot_date − last_order_date) > 180 days
- active:   (snapshot_date − last_order_date) ≤ 180 days

## Why N = 180 days
[EITHER: a data-driven justification — e.g. "The median gap between consecutive orders
for repeat customers is ~X days; 180 days is roughly 2× that, so a customer silent
that long is very unlikely to return." Run the inter-order-gap query to fill in X.]
[OR, if you keep it simple: "180 days (6 months) is a standard mid-range inactivity
window for general e-commerce — long enough to avoid flagging normal gaps between
purchases, short enough to identify genuinely lapsed customers."]

## Modelling scope
Given the 3% repeat rate, the churn model is treated as a **demonstration of
technique on an imbalanced target**, not a high-accuracy business predictor. The
analytical weight of the project sits with the **cohort-retention and RFM analyses**,
which characterise customer behaviour directly. [State your choice: e.g. "Cohort and
RFM analyses are computed across all delivered-order customers" OR "restricted to
repeat-capable customers".]

## Known limitations
- The dataset ends abruptly in October 2018, so customers who purchased in mid-2018
  have had less opportunity to "churn" under a fixed 180-day window than 2016
  customers. The snapshot approach treats all customers by the same rule but does not
  correct for this unequal observation window.
- Churn is inferred from inactivity, not from an explicit cancellation, so it is a
  proxy rather than a ground-truth label.
  