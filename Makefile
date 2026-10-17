IMAGE:=explainer-ruby

RUNCMD:=podman run -i -t -v ".:/app" -w /app --rm $(ENTRYPOINT) $(IMAGE)

build:
	podman build -t explainer-ruby -f Dockerfile

bash:
	$(RUNCMD) /usr/bin/bash

run:
	$(RUNCMD) $(args)

ruby-run:
	$(RUNCMD) ruby $(args)

irb:
	ENTRYPOINT="--entrypoint irb"
	$(RUNCMD)

docs:
	$(RUNCMD) rdoc

test:
	$(RUNCMD) rspec $(args)