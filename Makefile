
up:
	docker-compose -f ./docker-compose.yml up -d

stop:
	docker-compose stop

log:
	docker-compose logs

sabnzbd:
	docker exec -ti sabnzbd bash

sonarr:
	docker exec -ti sonarr bash
