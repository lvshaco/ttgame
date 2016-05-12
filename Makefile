.PHONY: all clean res convres proto client 

all: proto

define prototo
	mkdir -pv res/pb
	rm -f res/pb/*
	mkdir -pv pbh
	rm -f pbh/*	
	cd tool/pb && lua protoc.lua p2c ../../proto ../../pbh ../res/pb
	cd proto && \
	for p in *.proto; \
	do \
		protoc --cpp_out=../pbh -o ../res/pb/$${p%.proto}.pb $$p; \
	done
	mkdir -pv lua/msg && mv pbh/*.lua lua/msg
endef

proto:
	@$(prototo)	

convres:
	@cd tool && python exceltoxmlgen.py ../excel ../excel/excelto_tmpl.xml
	@cd tool && \
		python excelto.py \
		../excel/excelto.xml \
		../excel lua=../res/lua \
		&& python tpltcollect.py ../res/lua ../res/lua/__alltplt.lua \
	
res: convres

dist: proto res
	rm -rf server.tgz
	tar -zcf server.tgz \
		shaco-foot \
		bin/shaco \
		bin/*.so \
		bin/*.lso \
		bin/config_self \
		bin/config \
		bin/config-cli \
		res/lua/*.lua \
		res/pb/*.pb \
		sql/*.sql \
		lua/msg/*.lua \
		lua/game/*.lua

dev:
	tar -zcf server_dev.tgz \
		res/lua/*.lua \
		lua/base/*.lua \
		lua/node/*.lua \
		lua/msg/*.lua \
		lua/test/*.lua \
		lua/game/*.lua \
		lua/gameredis/*.lua \
		lua/db/*.lua \
		lua/dblog/*.lua \
		proto/*.proto

upver:
	cd ~/code/lshaco && make server
	cp -r ~/server/bin .

client:
	tar -zcf ~/msg.tgz \
		res/pb/*.pb \
		pbh/*.pb.cc \
		pbh/*.pb.h \
		proto/*.proto

clean:
	rm -rf res pbh lua/msg
