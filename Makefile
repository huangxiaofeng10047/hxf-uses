.PHONY: clean
clean:
	rm -rf node_module
build-image:
	docker build -t hxf-use:v1.0 .

run-image:
	docker run -p 3000:80 hxf-use:v1.0
