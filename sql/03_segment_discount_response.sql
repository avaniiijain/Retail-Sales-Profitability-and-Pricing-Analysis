--- Q3: HOW DO DIFFERENT CUSTOMER SEGMENTS RESPOND TO DISCOUNTING?

-- Business context:
-- Questions 1 and 2 showed that promotional profitability varies
-- substantially by product and discount depth. This analysis shifts
-- the focus to customer segments to determine whether Consumer,
-- Corporate, and Home Office customers exhibit meaningfully different
-- profitability and sales-activity patterns under discounting.


-- Key Finding:
-- All three customer segments exhibited remarkably similar
-- profitability patterns across discount levels. Profit margins
-- declined and loss rates increased as discount depth increased,
-- while the distribution of sales activity remained broadly
-- consistent across segments. Although Home Office frequently
-- ranked highest within individual discount tiers, the differences
-- between segments were relatively small compared with the impact
-- of discount depth itself.


-- Decision this enables:
-- Promotional pricing strategies should primarily be driven by
-- product economics and discount depth rather than customer
-- segment. Since Consumer, Corporate, and Home Office respond
-- similarly to discounting, pricing policies should emphasize
-- sustainable discount levels across all segments instead of
-- segment-specific discount strategies.


-- PART A: As discount depth increases, does profitability change 
-- differently across Consumer, Corporate, and Home Office?


SELECT
    segment,
    discount_bucket,
    discount_bucket_rank,
    COUNT(*)                                                           AS sales_records,
    ROUND(SUM(profit), 2)                                              AS total_profit,
    ROUND(SUM(sales), 2)                                               AS total_revenue,
    ROUND(SUM(profit)
        / NULLIF(SUM(sales),0)100, 2)                                 AS profit_margin_pct,
    SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END)              AS loss_orders,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT() * 100, 1
    )                                                                   AS loss_rate_pct
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY segment, discount_bucket, discount_bucket_rank
ORDER BY segment, discount_bucket_rank;


-- PART B: How is sales activity distributed across discount levels for each customer segment?
-- Shows how each customer segment's sales records and units sold
-- are distributed across discount buckets.
-- This is a descriptive analysis of observed sales activity.

WITH segment_discount_summary AS
(
    SELECT
        segment,
        discount_bucket,
        discount_bucket_rank,
        COUNT(*)                                                    AS sales_records,
        SUM(quantity)                                               AS total_units
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY segment, discount_bucket, discount_bucket_rank
)
SELECT
    segment,
    discount_bucket,
    sales_records,
    ROUND(sales_records * 100.0
        / NULLIF(SUM(sales_records) OVER
        (PARTITION BY segment),0),2)                           AS segment_sales_record_share_pct,
total_units,
ROUND(total_units * 100.0
    / NULLIF(SUM(total_units) OVER 
    (PARTITION BY segment),0),2)                               AS segment_unit_share_pct
FROM segment_discount_summary
ORDER BY segment, discount_bucket_rank;


-- PART C: Which customer segment performs best within each discount tier?
-- Compares segment profitability at the same discount level and ranks
-- segments by profit margin to account for differences in segment size.

WITH segment_tier AS (
    SELECT
        segment,
        discount_bucket,
        discount_bucket_rank,
        COUNT(*)                                                        AS sales_records,
        ROUND(SUM(sales), 2)                                            AS total_revenue,
        ROUND(SUM(profit), 2)                                           AS total_profit,
    ROUND(SUM(profit)
        / NULLIF(SUM(sales),0)*100, 2)                              AS profit_margin_pct,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100,2)                                         AS loss_rate_pct

FROM SuperstoreDB.dbo.vw_superstore
GROUP BY segment, discount_bucket, discount_bucket_rank
)
SELECT
    discount_bucket,
    segment,
    sales_records,
    total_revenue,
    total_profit,
    profit_margin_pct,
    loss_rate_pct,
    DENSE_RANK() OVER (
        PARTITION BY discount_bucket
        ORDER BY profit_margin_pct DESC
    )                                                                   AS profitability_rank_within_tier
FROM segment_tier
ORDER BY discount_bucket_rank, profitability_rank_within_tier;
