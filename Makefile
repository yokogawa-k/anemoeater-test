SHELL := /bin/bash

COMPOSE_VERSION := "1.22.0"
COMPOSE         := ./bin/docker-compose
DURATION        := 180
TEST_TYPES      := slowlog binlog tcpdump
ANEMOEATER      ?= ~/anemoeater/anemoeater

default: test

logs: build
	$(COMPOSE) up -d
	@for i in {10..0}; do \
		if $(COMPOSE) exec mysql mysql -h127.0.0.1 -e 'select 1' &> /dev/null; then \
			echo "MySQL container is up!!"; \
			break; \
		fi; \
		if [ "$${i}" -eq 0 ]; then exit 2;fi; \
		sleep 1; \
	done
	$(COMPOSE) exec -d --privileged sysbench sh -c 'tcpdump -s 65535 -x -nn -q -tttt -i any port 3306 > mysql.tcp.txt'
	$(COMPOSE) exec mysql mysql -e 'create database sbtest'
	$(COMPOSE) exec sysbench sysbench oltp_common --num-threads=1 --mysql-host=mysql --mysql-user=root prepare
	$(COMPOSE) exec sysbench sysbench oltp_read_write --num-threads=1 --time=$(DURATION) --rate=10 --mysql-host=mysql --mysql-user=root --report-interval=10 run
	$(COMPOSE) exec sysbench sh -c 'kill $$(pgrep tcpdump)'
	$(COMPOSE) stop sysbench mysql
	mkdir -p ./data
	docker cp $$($(COMPOSE) ps -q sysbench):/mysql.tcp.txt ./data/mysql-tcpdump.log
	docker cp $$($(COMPOSE) ps -q mysql):/var/lib/mysql/mysql-bin.000003 ./data/mysql-binlog.log
	docker cp $$($(COMPOSE) ps -q mysql):/var/lib/mysql/slow.log ./data/mysql-slowlog.log
	#$(COMPOSE) down

build: bin/docker-compose
	$(COMPOSE) build

down:
	$(COMPOSE) down

clean:
	rm -rf ./data/

bin/docker-compose:
	mkdir -p ./bin
	curl -L https://github.com/docker/compose/releases/download/$(COMPOSE_VERSION)/docker-compose-$$(uname -s)-$$(uname -m) -o ./bin/docker-compose
	chmod +x ./bin/docker-compose

#define type-tests-template
#.PHONY: test-$(1)
#test-$(1):
#ifeq (,$(wildcard data/mysql-$(1).log))
#	$(MAKE) logs
#endif
#	$(ANEMOEATER) --type $(1) --cell=1 --report=1 data/mysql-$(1).log
#	./anemometer_check.sh
#endef
#
#test: $(addprefix test-, $(TEST_TYPES))
#
#$(foreach _type,$(TEST_TYPES),$(eval $(call type-tests-template,$(_type))))

test-%:
	@if [[ ! -f data/mysql-$*.log ]]; then \
		$(MAKE) logs; \
	fi
	$(ANEMOEATER) --type $* --cell=1 --report=1 data/mysql-$*.log
	./anemometer_check.sh

test: $(addprefix test-, $(TEST_TYPES))

.PHONY: logs build down clean test
