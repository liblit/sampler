-- find builds with the most runs

SELECT build_distribution, application_name, application_version, application_release, build_date, count(*) as repeats
FROM run NATURAL JOIN build
GROUP BY run.build_id
ORDER BY repeats DESC;
