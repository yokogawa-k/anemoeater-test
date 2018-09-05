[yoku0825/anemoeater](https://github.com/yoku0825/anemoeater) のテストをするための Dockerfile など

sysbench によりダミーデータが生成され、デフォルトでは `~/anemoeater/anemoeater` を実行して各ファイルの投入やその結果の確認ができる

```console
$ make
make[1]: Entering directory '/home/admin/anemoeater-test'
./bin/docker-compose build
mysql uses an image, skipping
Building sysbench
Step 1/4 : FROM debian
 ---> 3bbb526d2608
Step 2/4 : ENV DEBIAN_FRONTEND noninteractive
 ---> Using cache
 ---> a57deafd6b7c
Step 3/4 : RUN set -ex     && apt-get update     && apt-get install -y --no-install-recommends         tcpdump         curl         ca-certificates         gnupg         procps
 ---> Using cache
 ---> 1b8fad153100
Step 4/4 : RUN set -ex     && curl -sLO https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh     && bash script.deb.sh     && apt-get install -y sysbench     && rm script.deb.sh
 ---> Using cache
 ---> 5529873ef0f2

Successfully built 5529873ef0f2
Successfully tagged sysbench:latest
./bin/docker-compose up -d
Creating network "anemoeater-test_default" with the default driver
Creating anemoeater-test_sysbench_1 ... done
Creating anemoeater-test_mysql_1    ... done
MySQL container is up!!
./bin/docker-compose exec -d --privileged sysbench sh -c 'tcpdump -s 65535 -x -nn -q -tttt -i any port 3306 > mysql.tcp.txt'
./bin/docker-compose exec mysql mysql -e 'create database sbtest'
./bin/docker-compose exec sysbench sysbench oltp_common --num-threads=1 --mysql-host=mysql --mysql-user=root prepare
sysbench 1.0.15 (using bundled LuaJIT 2.1.0-beta2)

Creating table 'sbtest1'...
Inserting 10000 records into 'sbtest1'
Creating a secondary index on 'sbtest1'...
./bin/docker-compose exec sysbench sysbench oltp_read_write --num-threads=1 --time=180 --rate=10 --mysql-host=mysql --mysql-user=root --report-interval=10 run
sysbench 1.0.15 (using bundled LuaJIT 2.1.0-beta2)

Running the test with following options:
Number of threads: 1
Target transaction rate: 10/sec
Report intermediate results every 10 second(s)
Initializing random number generator from current time


Initializing worker threads...

Threads started!

[ 10s ] thds: 1 tps: 11.00 qps: 219.96 (r/w/o: 153.97/43.99/22.00) lat (ms,95%): 52.89 err/s: 0.00 reconn/s: 0.00
[ 10s ] queue length: 0, concurrency: 0
[ 20s ] thds: 1 tps: 9.30 qps: 187.91 (r/w/o: 131.60/37.60/18.70) lat (ms,95%): 51.94 err/s: 0.00 reconn/s: 0.00
[ 20s ] queue length: 0, concurrency: 0

~~snip~~

./bin/docker-compose exec sysbench sh -c 'kill $(pgrep tcpdump)'
./bin/docker-compose stop sysbench mysql
Stopping anemoeater-test_mysql_1    ... done
Stopping anemoeater-test_sysbench_1 ... done
mkdir -p ./data
docker cp $(./bin/docker-compose ps -q sysbench):/mysql.tcp.txt ./data/mysql-tcpdump.log
docker cp $(./bin/docker-compose ps -q mysql):/var/lib/mysql/mysql-bin.000003 ./data/mysql-binlog.log
docker cp $(./bin/docker-compose ps -q mysql):/var/lib/mysql/slow.log ./data/mysql-slowlog.log
#./bin/docker-compose down
make[1]: Leaving directory '/home/admin/anemoeater-test'
~/anemoeater/anemoeater --type slowlog --cell=1 --report=1 data/mysql-slowlog.log
Docker container starts with 172.17.0.3.
URL will be http://127.0.0.1:32815/anemometer
processing 2018-09-05 06:41:00 at mysql-slowlog.log.
processing 2018-09-05 06:42:00 at mysql-slowlog.log.
processing 2018-09-05 06:43:00 at mysql-slowlog.log.
processing 2018-09-05 06:44:00 at mysql-slowlog.log.
processing 2018-09-05 06:44:00 at mysql-slowlog.log.
./anemometer_check.sh
check anemometer access
[OK] access anemometer(http://127.0.0.1:32815/anemometer/) succeeded
check mysql records
[OK] records in 'global_query_review'
[OK] records in 'global_query_review_history'
~/anemoeater/anemoeater --type binlog --cell=1 --report=1 data/mysql-binlog.log
Docker container starts with 172.17.0.4.
URL will be http://127.0.0.1:32816/anemometer
Warning: mysqlbinlog: unknown variable 'loose-default-character-set=utf8mb4'
processing 2018-09-05 06:41:00 at mysql-binlog.log.
processing 2018-09-05 06:42:00 at mysql-binlog.log.
processing 2018-09-05 06:43:00 at mysql-binlog.log.
processing 2018-09-05 06:44:00 at mysql-binlog.log.
processing 2018-09-05 06:44:00 at mysql-binlog.log.
./anemometer_check.sh
check anemometer access
[OK] access anemometer(http://127.0.0.1:32816/anemometer/) succeeded
check mysql records
[OK] records in 'global_query_review'
[OK] records in 'global_query_review_history'
~/anemoeater/anemoeater --type tcpdump --cell=1 --report=1 data/mysql-tcpdump.log
Docker container starts with 172.17.0.5.
URL will be http://127.0.0.1:32817/anemometer
processing 2018-09-05 06:41:00 at mysql-tcpdump.log.
processing 2018-09-05 06:42:00 at mysql-tcpdump.log.
processing 2018-09-05 06:43:00 at mysql-tcpdump.log.
processing 2018-09-05 06:44:00 at mysql-tcpdump.log.
processing 2018-09-05 06:44:00 at mysql-tcpdump.log.
./anemometer_check.sh
check anemometer access
[OK] access anemometer(http://127.0.0.1:32817/anemometer/) succeeded
check mysql records
[OK] records in 'global_query_review'
[OK] records in 'global_query_review_history'
```
