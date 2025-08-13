# Trouble

## "Temporary failure resolving" in `docker build -t crossimage crossimage/`

```
$ docker build -t crossimage crossimage/
[...]
 => ERROR [2/2] RUN dpkg --add-architecture armhf &&     apt-get update &&     apt-get install -y libusb-1.0-0-dev:armhf libftdi1-dev:armhf libudev-dev:  9.3s
------                                                                                                                                                         
 > [2/2] RUN dpkg --add-architecture armhf &&     apt-get update &&     apt-get install -y libusb-1.0-0-dev:armhf libftdi1-dev:armhf libudev-dev:armhf:        
0.289 Err:1 http://archive.archive.ubuntu.com/ubuntu xenial InRelease                                                                                          
0.289   Temporary failure resolving 'archive.archive.ubuntu.com'                                                                                               
0.290 Err:2 http://security.archive.ubuntu.com/ubuntu xenial-security InRelease                                                                                
0.290   Temporary failure resolving 'security.archive.ubuntu.com'                                                                                              
0.293 Err:3 http://archive.archive.ubuntu.com/ubuntu xenial-updates InRelease
0.294   Temporary failure resolving 'archive.archive.ubuntu.com'
0.295 Err:4 http://archive.archive.ubuntu.com/ubuntu xenial-backports InRelease
0.295   Temporary failure resolving 'archive.archive.ubuntu.com'
5.295 Err:5 http://ports.ubuntu.com/ubuntu-ports xenial InRelease
5.295   Temporary failure resolving 'ports.ubuntu.com'
5.300 Err:6 http://ports.ubuntu.com/ubuntu-ports xenial-updates InRelease
5.300   Temporary failure resolving 'ports.ubuntu.com'
5.303 Err:7 http://ports.ubuntu.com/ubuntu-ports xenial-backports InRelease
5.303   Temporary failure resolving 'ports.ubuntu.com'
5.305 Err:8 http://ports.ubuntu.com/ubuntu-ports xenial-security InRelease
5.305   Temporary failure resolving 'ports.ubuntu.com'
5.309 Reading package lists...
7.025 W: Failed to fetch http://archive.archive.ubuntu.com/ubuntu/dists/xenial/InRelease  Temporary failure resolving 'archive.archive.ubuntu.com'
7.025 W: Failed to fetch http://archive.archive.ubuntu.com/ubuntu/dists/xenial-updates/InRelease  Temporary failure resolving 'archive.archive.ubuntu.com'
7.025 W: Failed to fetch http://archive.archive.ubuntu.com/ubuntu/dists/xenial-backports/InRelease  Temporary failure resolving 'archive.archive.ubuntu.com'
7.025 W: Failed to fetch http://security.archive.ubuntu.com/ubuntu/dists/xenial-security/InRelease  Temporary failure resolving 'security.archive.ubuntu.com'
7.025 W: Failed to fetch http://ports.ubuntu.com/ubuntu-ports/dists/xenial/InRelease  Temporary failure resolving 'ports.ubuntu.com'
7.025 W: Failed to fetch http://ports.ubuntu.com/ubuntu-ports/dists/xenial-updates/InRelease  Temporary failure resolving 'ports.ubuntu.com'
7.025 W: Failed to fetch http://ports.ubuntu.com/ubuntu-ports/dists/xenial-backports/InRelease  Temporary failure resolving 'ports.ubuntu.com'
7.025 W: Failed to fetch http://ports.ubuntu.com/ubuntu-ports/dists/xenial-security/InRelease  Temporary failure resolving 'ports.ubuntu.com'
7.025 W: Some index files failed to download. They have been ignored, or old ones used instead.
7.038 Reading package lists...
8.774 Building dependency tree...
9.043 Reading state information...
9.128 E: Unable to locate package libusb-1.0-0-dev:armhf
9.128 E: Couldn't find any package by glob 'libusb-1.0-0-dev'
9.128 E: Couldn't find any package by regex 'libusb-1.0-0-dev'
9.128 E: Unable to locate package libftdi1-dev:armhf
9.128 E: Unable to locate package libudev-dev:armhf
```

This is likely what it states - a *temporary* network failure??

But the author has seen it **TWICE**.

This is yet another GOOD reason to keep the Docker image around, once built.

**Failed on**

- 13-Feb-25 (5.30 pm EET); accessed from FI

