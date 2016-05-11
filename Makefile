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
	@cd tool && python exceltoxmlgen.py $(HOME)/.shaco_ttgame/excel $(HOME)/.shaco_ttgame/excel/excelto_tmpl.xml
	@cd tool && \
		python excelto.py \
		$(HOME)/.shaco_ttgame/excel/excelto.xml \
		$(HOME)/.shaco_ttgame/excel lua=../res/lua:formula=../res/lua \
		&& python tpltcollect.py ../res/lua ../res/lua/__alltplt.lua \
		&& mv ../res/lua/formula.lua ../lua/game \
	    && lua tplttable.lua && lua tpltcheck.lua
	
res: convres

dist: proto res
	rm -rf server.tgz
	tar -zcf server.tgz \
		shaco-foot \
		bin/shaco \
		bin/resolveip \
		bin/*.so \
		bin/*.lso \
		bin/*.pub \
		bin/config_self.def \
		bin/config_game \
		bin/config_cmdcli \
		bin/config_gmrobot \
		bin/config_test \
		res/lua/*.lua \
		res/pb/*.pb \
		sql/*.sql \
		lua/base/*.lua \
		lua/node/*.lua \
		lua/msg/*.lua \
		lua/test/*.lua \
		lua/game/*.lua \
		lua/gameredis/*.lua \
		lua/db/*.lua \
		lua/dblog/*.lua \

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

client_dir=~/common_include
client: proto
	svn up $(client_dir)/pbh
	svn up $(client_dir)/proto
	svn up $(client_dir)/pb
	svn up $(client_dir)/lua
	svn up $(client_dir)/msg
	mkdir -pv $(client_dir)/pbh 
	mkdir -pv $(client_dir)/proto 
	mkdir -pv $(client_dir)/pb
	mkdir -pv $(client_dir)/lua
	mkdir -pv $(client_dir)/msg
	cp pbh/* $(client_dir)/pbh 
	cp proto/* $(client_dir)/proto 
	cp res/pb/* $(client_dir)/pb
	cp lua/game/formula.lua $(client_dir)/lua
	cp lua/msg/msg_client.lua lua/msg/enum.lua lua/msg/struct.lua $(client_dir)/msg
	svn add $(client_dir)/* --force
	svn commit $(client_dir) -m "commit by make client"

clean:
	rm -rf res pbh lua/msg
