* install docker and docker-compose
* run `sudo usermod -ag docker ${user}`
* clone this to `~/docker`
* Create .env file with:

** puid and pgid - the user id of the linux user, who we want to run the home server apps as, and group id of docker. Use `id` command

```
PUID=userid number
PGID=docker group id number
TIME_ZONE=America/New_York
DL_DIR={location for downloads}
```

* Create docker folder
```
sudo setfacl -Rdm g:docker:rwx ~/docker
sudo chmod -R 775 ~/docker
```
