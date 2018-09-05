#!/bin/bash

set -e
set -u

CONTAINER=$(docker ps -ql)
PORT=$(docker inspect -f '{{ (index (index .NetworkSettings.Ports "80/tcp") 0).HostPort }}' ${CONTAINER})
URL="http://127.0.0.1:${PORT}/anemometer/"

echo "check anemometer access"
if [[ $(curl -LI -o /dev/null -w '%{http_code}' -s ${URL}) -eq 200 ]]; then
  echo "[OK] access anemometer(${URL}) succeeded"
else
  echo "[ERR] anemoeter access error"
  (set -x; curl -LI ${URL})
  exit 2
fi

echo "check mysql records"
if [[ $(docker exec ${CONTAINER} mysql slow_query_log -Ne 'select count(*) from global_query_review') -gt 1 ]]; then
  echo "[OK] records in 'global_query_review'"
else
  echo "[ERR] anemoeter mysql 'global_query_review' records error"
  (set -x; docker exec ${CONTAINER} mysql slow_query_log -Ne 'select count(*) from global_query_review')
  exit 2
fi

if [[ $(docker exec ${CONTAINER} mysql slow_query_log -Ne 'select count(*) from global_query_review_history') -gt 1 ]]; then
  echo "[OK] records in 'global_query_review_history'"
else
  echo "[ERR] anemoeter mysql 'global_query_review_history' records error"
  (set -x; docker exec ${CONTAINER} mysql slow_query_log -Ne 'select count(*) from global_query_review_history')
  exit 2
fi

