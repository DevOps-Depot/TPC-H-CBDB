#!/bin/bash

set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

session_id=${1}

step="testing_${session_id}"

init_log ${step}

sql_dir=${PWD}/${session_id}

function generate_queries()
{
	#going from 1 base to 0 base
	tpch_id=$((session_id))
	tpch_query_name="query_${tpch_id}.sql"
	query_id=100
	
	for order in $(seq 1 22); do
		query_id=$((query_id+1))
		q=$(printf %02d ${query_id})
		template_filename=query${session_id}.tpl
		start_position=""
		end_position=""
		query_number=$(grep begin $sql_dir/$tpch_query_name | head -n"$order" | tail -n1 | awk -F ' ' '{print $2}' | awk -F 'q' '{print $2}')
		query_number=${query_number:0:2}
		start_position=$(grep -n "begin q""$query_number" $sql_dir/$tpch_query_name | awk -F ':' '{print $1}')
		end_position=$(grep -n "end q""$query_number" $sql_dir/$tpch_query_name | awk -F ':' '{print $1}')
		echo $order

		#get the query number (the order of query execution) generated by dsqgen
		filename=${query_id}.${BENCH_ROLE}.${query_number}.sql
		#add explain analyze 
		echo "print \"set role ${BENCH_ROLE};\\n:EXPLAIN_ANALYZE\\n\" > ${sql_dir}/${filename}"

		printf "set role ${BENCH_ROLE};\nset search_path=${SCHEMA_NAME},public;\n" > ${sql_dir}/${filename}

		for o in $(cat ${TPC_H_DIR}/01_gen_data/optimizer.txt); do
        	q2=$(echo ${o} | awk -F '|' '{print $1}')
       	 	if [ "${order}" == "${q2}" ]; then
          		optimizer=$(echo ${o} | awk -F '|' '{print $2}')
        	fi
    	done
		printf "set optimizer=${optimizer};\n" >> ${sql_dir}/${filename}
		printf "set statement_mem=\"${STATEMENT_MEM_MULTI_USER}\";\n" >> ${sql_dir}/${filename}
		printf ":EXPLAIN_ANALYZE\n" >> ${sql_dir}/${filename}
		
		echo "sed -n \"$start_position\",\"$end_position\"p $sql_dir/$tpch_query_name >> $sql_dir/$filename"
		sed -n "$start_position","$end_position"p $sql_dir/$tpch_query_name >> $sql_dir/$filename
		echo "Completed: ${sql_dir}/${filename}"
	done
	echo "rm -f ${sql_dir}/query_*.sql"
	rm -f ${sql_dir}/${tpch_query_name}
}

if [ "${RUN_QGEN}" = "true" ]; then
  generate_queries
fi

tuples="0"
for i in ${sql_dir}/*.sql; do
	start_log
	id=${i}
	schema_name=${session_id}
	table_name=$(basename ${i} | awk -F '.' '{print $3}')

	if [ "${EXPLAIN_ANALYZE}" == "false" -o "${table_name}" == "15"]; then
		log_time "psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE="" -f ${i} | wc -l"
		tuples=$(psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE="" -f ${i} | wc -l; exit ${PIPESTATUS[0]})
		tuples=$((tuples - 1))
	else
		myfilename=$(basename ${i})
		mylogfile="${TPC_H_DIR}/log/${session_id}.${myfilename}.multi.explain_analyze.log"
		log_time "psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE=\"EXPLAIN ANALYZE\" -f ${i}"
		psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE="EXPLAIN ANALYZE" -f ${i} > ${mylogfile}
		tuples="0"
	fi
		
	#remove the extra line that \timing adds
	print_log ${tuples}
done

end_step ${step}
