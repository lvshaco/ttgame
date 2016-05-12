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
