* install docker and docker-compose
* run `sudo usermod -aG docker ${user}`
* clone this to `~/docker`
* Create .env file with:

** pgid - group id of docker. Use `id` command

```
PGID=docker group id number
TIME_ZONE=America/New_York
DL_DIR={location for downloads}
SAB_ID=id of sabnzbd user
SON_ID="" sonarr user
DEL_ID="" deluge user
```

* Set perms for any folders to group usenet
```
 $ chgrp -R usenet /[media_folder]
#     $ find /media -type f -exec chmod 664 {} \;
#     $ find /media -type d -exec chmod 775 {} \;
```

```
docker-compose -f ~/docker/docker-compose.yml up -d
```

# User permissions

1. Create a group that has access to your media folder(s).
 * `sudo groupadd usenet`
 * Get the group id for `usenet`:
    ```
    $ getent group usenet | awk -F: '{printf "%s GID=%d\n", $1, $3}
    usenet GID=1001
    ```
 * Recursively change the permissions and group of your media storage
   directories so that usenet has access.  Something like:
   ```
   $ chown -R tom:usenet /media
   # Change all folders and files
    sudo chmod -R 775 TV
   # Change all files to 664
    sudo find TV -type f -print0 |xargs -0 chmod 664
   ```

2. Create a system user for all programs (sonarr, sabnzbd, etc) with our usenet groupid.
   ```
   $ sudo useradd -G usenet -m sabnzbd
   Adding system user `sonarr' (UID 126) ...
   Adding new user `sonarr' (UID 124) with group `usenet' ...
   Not creating home directory `/home/sonarr'.
   ```

