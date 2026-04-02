SET SQL_SAFE_UPDATES = 0;

UPDATE customers 
SET gender = NULL 
WHERE gender = '';

UPDATE customers 
SET age = NULL 
WHERE age = '';

Alter table customers MODIFY age INT NULL;

CREATE TABLE Transactions 
(
date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL(10,2)
);

SELECT * FROM finalproject.transactions;

-- список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период, 
-- средний чек за период с 01.06.2015 по 01.06.2016, 
-- средняя сумма покупок за месяц, 
-- количество всех операций по клиенту за период;

SELECT 
    c.Id_client,
    ROUND(AVG(t.Sum_payment),2) AS avg_check,
    ROUND((SUM(t.Sum_payment)/ 12),2) AS avg_monthly_sum,
    COUNT(t.Id_check) AS total_operations
FROM customers c
JOIN transactions t ON c.Id_client = t.id_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
GROUP BY c.Id_client
HAVING COUNT(DISTINCT DATE_FORMAT(t.date_new, '%Y-%m')) = 12;


-- информацию в разрезе месяцев:
-- средняя сумма чека в месяц;
-- среднее количество операций в месяц;
-- среднее количество клиентов, которые совершали операции;
-- долю от общего количества операций за год и долю в месяц от общей суммы операций;
-- вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    SUM(t.sum_payment) / COUNT(t.id_check) AS avg_check_amount,
    COUNT(t.id_check) AS operations_count,
    COUNT(DISTINCT t.id_client) AS active_clients_count,

    COUNT(t.id_check) * 1.0 / (SELECT COUNT(*) FROM transactions) AS share_ops_total,
    SUM(t.sum_payment) * 1.0 / (SELECT SUM(sum_payment) FROM transactions) AS share_sum_total,

    -- гендер по операциям
    COUNT(CASE WHEN c.Gender = 'M' THEN 1 END) * 1.0 / COUNT(t.id_check) AS ops_gender_m,
    COUNT(CASE WHEN c.Gender = 'F' THEN 1 END) * 1.0 / COUNT(t.id_check) AS ops_gender_f,
    COUNT(CASE WHEN c.Gender IS NULL OR c.Gender = 'NA' THEN 1 END) * 1.0 / COUNT(t.id_check) AS ops_gender_na,

    -- гендер по сумме
    SUM(CASE WHEN c.Gender = 'M' THEN t.sum_payment ELSE 0 END) * 1.0 /
        SUM(t.sum_payment) AS spend_share_m,
    SUM(CASE WHEN c.Gender = 'F' THEN t.sum_payment ELSE 0 END) * 1.0 /
        SUM(t.sum_payment) AS spend_share_f,
    SUM(CASE WHEN c.Gender IS NULL OR c.Gender = 'NA' THEN t.sum_payment ELSE 0 END) * 1.0 /
        SUM(t.sum_payment) AS spend_share_na

FROM transactions t
LEFT JOIN customers c 
    ON t.id_client = c.Id_client

GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
ORDER BY month;

-- возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
-- с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

SELECT 
    CASE 
        WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age < 10 THEN '0-9'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.Age >= 70 THEN '70+'
    END AS age_group,

    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    QUARTER(t.date_new) AS quarter,

    COUNT(t.id_check) AS operations_count,
    SUM(t.sum_payment) AS total_sum,
    SUM(t.sum_payment) / COUNT(t.id_check) AS avg_check,
    COUNT(t.id_check) * 1.0 / COUNT(DISTINCT QUARTER(t.date_new)) AS avg_ops_per_quarter,
    COUNT(t.id_check) * 1.0 / (SELECT COUNT(*) FROM transactions) AS ops_share,
    SUM(t.sum_payment) * 1.0 / (SELECT SUM(sum_payment) FROM transactions) AS sum_share

FROM transactions t
LEFT JOIN customers c 
    ON t.id_client = c.Id_client
GROUP BY 
    age_group,
    month,
    quarter
ORDER BY age_group, quarter, month;
