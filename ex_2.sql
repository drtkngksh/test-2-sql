WITH
  q AS (
    SELECT transactions.customer_id
    FROM public.transaction_test_nick transactions
      JOIN public.customers_test_nick customers
        ON transactions.customer_id = customers.customer_id
    WHERE (
      transactions.standard_cost <> ''
      AND transactions.standard_cost IS NOT NULL
      AND transactions.order_status = 'Approved'
      AND transactions.customer_id IN (
        SELECT customer_id
         FROM public.transaction_test_nick transactions
        GROUP BY transactions.customer_id
        HAVING (
          MAX(extract(MONTH FROM to_date(transaction_date, 'DD-MM-YYYY'))) = 12
          AND ((MAX(extract(MONTH FROM to_date(transaction_date, 'DD-MM-YYYY'))) - MIN(EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY')))) + 1) = COUNT(DISTINCT EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY')))
        )
      )
    )
    GROUP BY transactions.customer_id
  ),
  q2 AS (
SELECT latest_transactions.customer_id, latest_transaction.transaction_id, latest_transaction.brand, latest_transactions.latest_transaction_date
    FROM (
      SELECT
        transactions.customer_id,
        MAX(TO_DATE(transactions.transaction_date, 'DD-MM-YYYY')) AS latest_transaction_date
      FROM public.transaction_test_nick transactions
        JOIN public.customers_test_nick customers
          ON transactions.customer_id = customers.customer_id
      WHERE (
        transactions.standard_cost <> ''
        AND transactions.standard_cost IS NOT NULL
        AND transactions.order_status = 'Approved'
        AND transactions.customer_id IN (
          SELECT customer_id
          FROM public.transaction_test_nick
          GROUP BY customer_id
          HAVING (
            MAX(EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY'))) = 12
            AND ((MAX(EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY'))) - MIN(EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY')))) + 1) = COUNT(DISTINCT EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY')))
          )
        )
      )
      GROUP BY transactions.customer_id
    ) AS latest_transactions
      JOIN public.transaction_test_nick latest_transaction
        ON (
          latest_transactions.customer_id = latest_transaction.customer_id
          AND TO_DATE(latest_transaction.transaction_date, 'DD-MM-YYYY') = latest_transactions.latest_transaction_date
        )
    ORDER BY latest_transactions.customer_id
  )
  
  
/* SELECT
  transactions.customer_id,
  MIN(TO_DATE(transactions.transaction_date, 'DD-MM-YYYY')) FILTER (WHERE CAST(REPLACE(
    REPLACE(
      REPLACE(transactions.standard_cost, '[$]', ''),
      ',',
      '.'
    ),
    ' ',
    ''
  ) AS float) >= 1000) OVER (PARTITION BY transactions.customer_id) AS frs_date,
  transactions.brand
FROM public.transaction_test_nick transactions
WHERE (
  transactions.customer_id IN (
    SELECT customer_id
    FROM q
  )
  AND transactions.transaction_id IN (
    SELECT transaction_id
    FROM q2
  )
)
ORDER BY transactions.customer_id */

SELECT 
  transactions.customer_id,
  ROUND(AVG(CAST(REPLACE(
    REPLACE(
      REPLACE(transactions.standard_cost, '[$]', ''),
      ',',
      '.'
    ),
    ' ',
    ''
  ) AS float))) AS average_check

FROM public.transaction_test_nick AS transactions
WHERE transactions.customer_id IN (SELECT customer_id FROM q) 
GROUP BY transactions.customer_id;
ORDER BY transactions.customer_id;