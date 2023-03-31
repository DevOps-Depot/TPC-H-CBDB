SELECT split_part(description, '.', 1) as schema_name, round(extract('epoch' from duration),1) AS seconds 
FROM tpch_reports.sql 
WHERE tuples = -1
ORDER BY 1;
