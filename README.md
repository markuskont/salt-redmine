# salt-redmine
Deploy host redmine using saltstack

# vagrant

This repository is meant to be used as a local development environment. Easiest way to get started is to use virtualbox provider.

```
vagrant up
```

Vagrant environment will also deploy a dedicated saltmaster VM, in order to reflect realistic production setup. However, we do not pre-seed minion keys, allowing minion to generate new certificate requests upon each `vagrant up`. Therefore, developer must accept key manually within the saltmaster VM.

```
vagrant ssh saltmaster
sudo salt-key -L
sudo salt-key -A -y
salt '*' test.ping
```

Note that developer does not need superuser privileges to use salt execution modules as vagrant user. This is due to pre-configured ACL within salt-master config file. However, local system administration tasks (e.g. accepting certificate requests) still require elevation. You can deploy redmine within saltmaster VM once the vagrant environment is operational.

```
salt '*' state.highstate
```

## Requirements

This deployment has been tested on a PC host with following specs:
* Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz
* 16GB RAM
* 100Gig-ish free disk space
* Ubuntu 16.04 LTS
* Vagrant 1.8 and 1.9
* Functional internet connection (10-50Mbit/s)

Build time was somewhere between 15 and 30 minutes on this machine.
