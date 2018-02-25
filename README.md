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

## Deploying peers and resource hosts with Vagrant
You can easily build a peer with our Vagrant boxes. See https://github.com/subutai-io/packer/wiki/Box-User-Guide