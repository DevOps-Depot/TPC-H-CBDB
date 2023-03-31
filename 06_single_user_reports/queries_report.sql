SELECT split_part(description, '.', 2) AS id,  max(tuples) as tuples, round(min(extract('epoch' from duration)),1) AS duration
FROM tpch_reports.sql
WHERE tuples >= 0 
GROUP BY split_part(description, '.', 2)
ORDER BY id;
