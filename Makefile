BINARY=autospotting
LAMBDA_BINARY=autospotting_lambda
LOCAL_PATH=build/s3/dv

all: build_local

release: upload

build_local:
	go build $(GOFLAGS)

build_lambda:
	GOOS=linux GOARCH=amd64 go build -o ${LAMBDA_BINARY}

strip: build_lambda
	strip ${LAMBDA_BINARY}
	upx --lzma --best ${LAMBDA_BINARY}

install: strip
	CHECKSUM=$$(sha256sum ${LAMBDA_BINARY} | cut -f1 -d " " ); \
	FILENAME=${BINARY}_$$CHECKSUM ; \
	mkdir -p ${LOCAL_PATH} ; \
	mv ${LAMBDA_BINARY} ${LOCAL_PATH}/$$FILENAME ; \
	echo $$FILENAME > ${LOCAL_PATH}/latest_agent

upload: install
	aws s3 sync build/s3/ s3://cloudprowess/

test: build_local
	./autospotting -e  core/test_data/event.json -c core/test_data/context.json
