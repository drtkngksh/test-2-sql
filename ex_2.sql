WITH
  q AS (
  -- выбрать айди клиента из таблицы транзакций и соединить с таблицей клиентов по айди
    SELECT transactions.customer_id
    FROM public.transaction_test_nick transactions
      JOIN public.customers_test_nick customers
        ON transactions.customer_id = customers.customer_id
    WHERE (
    -- фильтровать транзакции, в которых стандартная стоимость не является пустой или нулевой, статус заказа одобрен, а ID клиента находится в подзапросе
      transactions.standard_cost <> ''
      AND transactions.standard_cost IS NOT NULL
      AND transactions.order_status = 'Approved'
      AND transactions.customer_id IN (
      -- выбрать айдишки из таблицы транзакций
        SELECT customer_id
         FROM public.transaction_test_nick transactions
        GROUP BY transactions.customer_id
        HAVING (
          MAX(extract(MONTH FROM to_date(transaction_date, 'DD-MM-YYYY'))) = 12 -- была ли последняя транзакция в декабре
          AND ((MAX(extract(MONTH FROM to_date(transaction_date, 'DD-MM-YYYY'))) - MIN(EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY')))) + 1) = COUNT(DISTINCT EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY')))
        )  -- отсеивать клиентов, которые не совершали покупки в каждом месяце года
      )
    )
    GROUP BY transactions.customer_id -- группировка по айди пользователя
  ),
  q2 AS (
  -- последние данные совершившего покупку пользователя в каждом месяце года
SELECT latest_transactions.customer_id, latest_transaction.transaction_id, latest_transaction.brand, latest_transactions.latest_transaction_date
    FROM (
    -- айди и последняя дата транзакции для клиентов, которые совершили покупку в каждом месяце года
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
          -- выбор айдишек клиентов из таблицы транзакций, группировка и фильтрация по тем, кто не совершал покупки в каждом месяце года
          SELECT customer_id
          FROM public.transaction_test_nick
          GROUP BY customer_id
          HAVING (
          -- фильтровать клиентов, которые не совершали покупки в каждом месяце года и была ли последняя транзакция в декабре
            MAX(EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY'))) = 12
            AND ((MAX(EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY'))) - MIN(EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY')))) + 1) = COUNT(DISTINCT EXTRACT(MONTH FROM TO_DATE(transaction_date, 'DD-MM-YYYY')))
          )
        )
      )
      GROUP BY transactions.customer_id
    ) AS latest_transactions -- джоин к таблице транзакций по айди и дате последней транзакции, чтобы получить детали последней транзакции
      JOIN public.transaction_test_nick latest_transaction
        ON (
          latest_transactions.customer_id = latest_transaction.customer_id
          AND TO_DATE(latest_transaction.transaction_date, 'DD-MM-YYYY') = latest_transactions.latest_transaction_date
        )
    ORDER BY latest_transactions.customer_id
  )
  
  
/* -- выбрать айди, дату первой операции, где стоимость больше или равна 1000 и бренд
SELECT
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
-- подзапрос для получения айди, совершивших покупку во все 12 месяцев года
  transactions.customer_id IN (
    SELECT customer_id
    FROM q
  )
  AND transactions.transaction_id IN ( -- подзапрос для получения последних транзакций для каждого клиента, совершившего покупку за все 12 месяцев года
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
  ) AS float))) AS average_check -- вывод среднего чека по айдишкам

FROM public.transaction_test_nick AS transactions
WHERE transactions.customer_id IN (SELECT customer_id FROM q) -- выполнение условия "покупки каждый месяц"
GROUP BY transactions.customer_id;
ORDER BY transactions.customer_id;
