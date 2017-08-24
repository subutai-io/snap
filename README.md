# Snap repository
Subutai snap repository objectives:
- deploy, test and upload new snap package to the Store by [Subutai CI](https://jenkins.subut.ai/) service 
- provide a way to build Subutai Agent snap package using [snapcraft](https://snapcraft.io/) tool
- local project deployment using autobuild script

As it comes from strings above - repository mainly aimed for continuois integration platform purposes, but it also enables 
"advanced" users to build and deploy Subutai project locally. In general, it is strongly recommended to use [Subutai 
launchers](https://subutai.io/installation.html) for Subutai deployament.

## Building snap package
Subutai Agent and CLI is a base for Subutai Peer deployment and it uses [snap](https://snapcraft.io/docs/snaps/intro) as 
default package format. If you are not interested in building Subutai snap package locally, you can skip this step and continue 
on "Deploying peer with autobuild"; pre-built snap package will be downloaded automatically from snap Store.
We are assuming that you have snapcraft tool already installed in your system ([if not](https://snapcraft.io/docs/build-snaps/))
and you are familiar with it. To build Subutai snap package follow these steps:
1) Clone repository.
   - **Dev** is actively changing and unstable though latest features are there
   - **Master** is stable pre-release branch for massive testing 
   - **Release** is a well tested and stable code
2) In the root of cloned directory run `./configure` script which will prepare snapcraft.yaml file according to branch you have cloned.
Switching between branches will require reconfiguring yaml file to aim corresponding branches of other Subutai daughter projects, 
so `./configure` again and `snapcraft clean`.
3) Run `snapcraft`. 

If these commands succeeds, you will see Subutai snap package next to snapcraft.yaml which may be used 
to install on Ubuntu Core OS (other systems not tested yet and may be unstable).

## Deploying peer with autobuild
Snap repository contains bash autobuild script which is intended to automate Subutai peer local deployment. It has several 
pre-requirements for both - user should be savvy in Linux systems and host system must have:
1) Hardware: at least 4 core CPU with enabled VT-X and 8Gb RAM
2) Software: Ubuntu OS, VirtaulBox, [Ubuntu Core](https://cdn.subut.ai:8338/kurjun/rest/raw/get?name=core.ova) imported, sshpass
3) Internet connection if Subutai snap package doesn't exist in the same directory

If your system mets these requirements you can simply run `./autobuild.sh` in the cloned directory and get the ready-to-use VM with
Subutai Agent installed in ~2-5 minutes. Autobuild output is pretty verbose, you will be able to see deployment process step by step and 
debug it in case of failure.

Autobuild supports Subutai virtual machine image export in ova format or in Vagrant box: `./autobuild.sh -e ova` or 
`./autobuild.sh -e box` accordingly. Also, it may deploy multiple VMs at once by reading configuration file: `./autobuild.sh -d peer.conf`.
Configuration format is following:  
```
PEER=1
RH=2
```  
where "Peer" is a number of VMs with Management container to be imported and RH is a number of resource hosts 
which each Management will have.
