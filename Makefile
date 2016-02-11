default: build

build:
	docker build -t image-builder-rpi .

sd-image: build
	docker run --rm --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e VERSION image-builder-rpi

shell: build
	docker run -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e VERSION image-builder-rpi bash

test:
	VERSION=dirty docker run --rm -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e VERSION image-builder-rpi bash -c "unzip /workspace/sd-card-rpi-dirty.img.zip && rspec --format documentation --color /workspace/builder/test/*_spec.rb"

vagrant:
	vagrant up

docker-machine: vagrant
	docker-machine create -d generic \
	  --generic-ssh-user $(shell vagrant ssh-config | grep ' User ' | cut -d ' ' -f 4) \
	  --generic-ssh-key $(shell vagrant ssh-config | grep IdentityFile | cut -d ' ' -f 4) \
	  --generic-ip-address $(shell vagrant ssh-config | grep HostName | cut -d ' ' -f 4) \
	  --generic-ssh-port $(shell vagrant ssh-config | grep Port | cut -d ' ' -f 4) \
	  image-builder-rpi

test-integration: test-integration-image test-integration-docker

test-integration-image:
	docker run --rm -ti -v $(shell pwd)/builder/test-integration:/serverspec:ro -e BOARD uzyexe/serverspec:2.24.3 bash -c "rspec --format documentation --color spec/hypriotos-image"

test-integration-docker:
	docker run --rm -ti -v $(shell pwd)/builder/test-integration:/serverspec:ro -e BOARD uzyexe/serverspec:2.24.3 bash -c "rspec --format documentation --color spec/hypriotos-image"

tag:
	git tag ${TAG}
	git push origin ${TAG}
