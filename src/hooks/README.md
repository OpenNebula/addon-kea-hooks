# ISC Kea Hooks

Documentation for Kea and hooks:

- https://jenkins.isc.org/job/Kea_doc/doxygen/
- https://jenkins.isc.org/job/Kea_doc/doxygen/df/d46/hooksdgDevelopersGuide.html
- https://jenkins.isc.org/job/Kea_doc/doxygen/de/df3/dhcpv4Hooks.html

## Custom hooks

Each hook directory has a source code directory named after its version - e.g.: `v1.0.0` or `v1.0`

There is allowed to have multiple source code directories with different versions - the naming is actually arbitrary but it should be named after the hook's version for a clarity...

Beside the hook's source code directories there are symlinks named after the compatible ISC Kea version...these points to the latest supported hook's source code and determine the build and support matrix (or whatever other scheme is chosen).

*For example: we are building ISC Kea version `1.6.0` and inside of our ONElease4 hook directory is the symlink `./1.6.0` pointing to the directory `./v1.0.0`, where the source code of this hook resides.*

The script now will know which hooks and what version of them can be built with the ISC Kea version currently being built. If no directory or symlink is present with the correspondent Kea version then this particular hook will be skipped - it will not be built and it will not be packaged.

### `kea-onelease-dhcp4`
#### Version: `1.1.0`

This is quite a simple hook to assign ONE lease for a client based on its HW (MAC) address. It will work properly only if clients have HW addresses generated in a particular way: **the last four bytes represent an IPv4 address**

