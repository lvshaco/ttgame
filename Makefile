.PHONY: all clean res convres proto client excel

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
	mkdir -pv server
	cp -r ~/server_linux/bin server/
	cp bin/config* server/bin/
	cp bin/redis*.conf*.def server/bin/
	cp -r res server/
	cp -r sql server/
	cp -r proto server/
	cp -r lua server/
	tar -zcf server.tgz server
	scp server.tgz tt:
	ssh tt "tar -zxf server.tgz -C . && cd server && ./start 1>/dev/null"
	rm -rf server.tgz
	rm -rf server
	cd ~/code/tiaotiao && ./foot

upver:
	cd ~/code/lshaco && make server
	cp -r ~/server/bin .

client:
	tar -zcf ~/msg.tgz \
		res/pb/*.pb \
		pbh/*.pb.cc \
		pbh/*.pb.h \
		proto/*.proto \
		excel/*.xlsx

excel:
	tar -zcf ~/excel.tgz \
		excel/*.xlsx

clean:
	rm -rf res pbh lua/msg
