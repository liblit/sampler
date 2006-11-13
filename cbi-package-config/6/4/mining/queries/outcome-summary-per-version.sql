-- outcome of each applcation's runs, ordered by crash frequency

SELECT
    *,
    round(crash / good::float * 1000) / 10 as crash_rate
FROM (
    SELECT
	application_name,
	application_version,
	min(build_date) as min_build_date,
	count(*) as count,
	sum(case when exit_status = 0 AND exit_signal = 0 then 1 else 0 end) AS good,
	sum(case when exit_status != 0 then 1 else 0 end) AS error,
	sum(case when exit_signal != 0 then 1 else 0 end) AS crash
    FROM run NATURAL JOIN build
    GROUP BY application_name, application_version
) AS subquery
ORDER BY application_name ASC, min_build_date ASC
