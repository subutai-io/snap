# Snap repository

Subutai snap repository objectives:
- deploy, test and upload new snap packages to the Store 
- provide a way to build the Subutai Agent snap package using the [snapcraft](https://snapcraft.io/) tool
- local peer deployment using the autobuild script

This repository is primarily for continuous integration, but it also enables "advanced" users to build and deploy Subutai peers and resource hosts locally. For simple easy to use installers that install all the components you need use the [Subutai 
Launchers](https://subutai.io/installation.html).

## Building the snap package
The Subutai Agent and CLI program is needed for Subutai Peer deployment and it uses [snap](https://snapcraft.io/docs/snaps/intro) packaging. If you are not interested in building the Subutai snap package locally, you can skip this step and continue to the section on "Deploying peers and resource hosts with autobuild"; the pre-built snap package can be downloaded automatically from the snap Store.

How?

We are assuming that you have snapcraft tool already installed in your system ([if not](https://snapcraft.io/docs/build-snaps/)) and you are familiar with how to use it. To build the Subutai snap package follow these steps:
1) Clone repository.
   - **Dev** is actively changing and unstable though latest features are there
   - **Master** is stable pre-release branch for massive testing 
   - **Release** is a well tested and stable code
2) In the root of cloned directory run `./configure` script which will prepare snapcraft.yaml file according to branch you have cloned.
Switching between branches will require reconfiguring the yaml file to point to corresponding branches of other Subutai daughter projects, 
so `./configure` again and `snapcraft clean`.
3) Run `snapcraft`. 

If these commands succeed, you will see the Subutai snap package next to snapcraft.yaml which may be used 
for installation on OS with snapd installed.

## Deploying peers and resource hosts with autobuild
The snap repository contains a bash script, autobuild, which automates the build of Subutai peers and resource hosts locally. It has several requirements:

1) Hardware: at least 4 core CPU with enabled VT-X and 8Gb RAM
2) Software: Ubuntu OS, VirtaulBox, [Ubuntu OS](https://cdn.subut.ai:8338/kurjun/rest/raw/get?name=ubuntu16.ova) imported, sshpass
3) Internet connection if Subutai snap package doesn't exist in the same directory

If your system meets these requirements you can simply run `./autobuild.sh` in the cloned directory and get the ready-to-use VM with the Subutai Agent installed in ~2-5 minutes. Autobuild output is pretty verbose, you will be able to see the deployment process take place step by step and debug it in case of failure.

Autobuild supports Subutai virtual machine image export in ova format or in Vagrant box: 
- `./autobuild.sh -e ova` or 
- `./autobuild.sh -e box` accordingly, 
- `./autobuild.sh -d peer.conf` to deploy multiple VMs at once by reading a configuration file with format: 

```
PEER=1
RH=2
```  

"PEER" specifies the number of VMs with a Management Console container imported in each. "RH" specifies the number of resource hosts for each peer.
