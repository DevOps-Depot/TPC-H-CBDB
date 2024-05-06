CREATE TABLE :schema_name.nation
(N_NATIONKEY INTEGER, 
N_NAME CHAR(25), 
N_REGIONKEY INTEGER, 
N_COMMENT VARCHAR(152))
USING :ACCESS_METHOD
WITH (:STORAGE_OPTIONS)
:DISTRIBUTED_BY;
