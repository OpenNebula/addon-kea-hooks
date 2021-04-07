# ISC Kea

Repository for building **[ISC Kea](https://www.isc.org/kea/)** software and **hook(s)** on **Alpine Linux** for **[OpenNebula's VNF appliance](https://docs.opennebula.io/appliances/service/vnf.html)**.

**NOTE**: The custom **ONELease** Hook for ISC Kea is under `src/hooks`.

**IMPORTANT**: The original [addon-kea-hooks](https://github.com/ospalax/addon-kea-hooks) repo is archived and this one serves as the official upstream from now on.

## OpenNebula VNF

One of the VNFs for [OpenNebula's VNF appliance](https://docs.opennebula.io/appliances/service/vnf.html) is a [dhcp](https://docs.opennebula.io/appliances/service/vnf.html#function-dhcp4) and Kea with its custom hooks was the best solution for our requirement (matching HW address with the IP lease) - `dnsmasq` has some hook system too, but they are triggered too late (after the lease is actually done). Kea's hooks are more granular and hooked onto more places during the process, which scratches our itch.

## Content overview

Here is a layout of this repository:

```
ikea/
├── artifacts/          # Ready to use builds
├── Dockerfile
├── extra/              # Some handy scripts
├── CHANGELOG.md
├── ikea.sh
├── LICENSE
├── Makefile
├── Makefile.config
├── README.md
├── src/
│   ├── hooks/          # Custom hooks
│   └── tools/          # Custom tools
└── tools/              # Build helpers
```

* `artifacts`: Here are already build and packed releases
* `src`: All custom work
* `src/hooks`: Custom Kea hooks
* `src/tools`: Custom Kea related scripts and tools
* **The rest is build related**

## Usage

First of all you need to have installed [**`docker`**](https://www.docker.com/) and `make` command. This project (if successful) will create a few artifacts:

- docker image with built and installed ISC Kea (also saved as a tar)
- an archive with ISC Kea compiled binaries (installation prefix)

The archive is used as a artifact for ONE VNF appliance - rebuilding ISC Kea with each appliance build would be too time-consuming.

### List default build parameters

There is no `configure` script so just edit or set the environmental variables which have defaults here:

```
% cat Makefile.config
```

### Default build

```
% make
% ls -l build
```

### OpenNebula build

For OpenNebula's ONE VNF appliance there exists a handy script (adjust `MAKE_JOBS` to your setup):

```
% ./extra/onekea.sh
```

For example with eight parallel jobs (instead of the default four):

```
% MAKE_JOBS=8 ./extra/onekea.sh
```

Or do something like this:

```
% env MAKE_JOBS=8 KEA_INSTALLPREFIX=/opt/one-appliance/kea make
```

## Hooks

To build hook(s) in this repo and package it with the artifact you must use variable `INSTALL_HOOKS` - it will build and install only that hook which has corresponding `KEA_VERSION`. Check the default version in `Makefile.config` or set it on the command line:

```
% env MAKE_JOBS=8 INSTALL_HOOKS=yes KEA_VERSION=1.6.0 make
```

Hook's source code can be found under `src/hooks` directory: `src/hooks/<hook>/<kea version>`

Custom hook libraries (build binaries) are packaged with the rest of the Kea software and they can be found under: `<KEA_INSTALLPREFIX>/lib/kea/hooks/`

**Even if all hooks are build, installed and packaged it does not mean that any of it will be loaded and used...what hook (library) is loaded and activated on Kea's startup is ultimately decided by your config file.**

## Tools

The directory `src/tools` is intended for helper tools and scripts directed to the ISC Kea runtime - that means they have nothing to do with the building of `ikea` as opposed to the `tools` directory under root of this repository...

- **`kea-config-generator`**: designed for OpenNebula's VNF appliance, but can be used elsewhere too

### kea-config-generator

It creates a `kea-dhcp4.conf` config file based on the given arguments. When no arguments is given it will create a config based on some simple heuristics.

The intent behind this script is to support OpenNebula's VNF appliance, but it is generic enough to be used anywhere where Kea's config file is to be autogenerated.

---

## Known Issues

---

## Motivation

Originally I decided to create this repo to build ISC Kea manually and use its artifacts in the appliance until Alpine kea packages are fixed and in stable branch...

These issues should have been already fixed with recent Alpine and/or ISC Kea:

### log4cplus problem

~~Kea packages built for Alpine are only in Edge and very unstable. I encountered a problem when kea binaries have been used as (on Alpine):~~

```
# ./kea-dhcp4 -c /etc/kea/kea-dhcp4.conf
kea-dhcp4: Fatal error during start up: log4cplus is not initialized and implicit initialization is turned off
```

Bugreports already existed:

- https://gitlab.isc.org/isc-projects/kea/issues/625
- https://gitlab.alpinelinux.org/alpine/aports/issues/10480

### Alpine kea packages dependency problem

~~Newest version of kea packages in Edge have for a change broken dependency last time I checked.~~

