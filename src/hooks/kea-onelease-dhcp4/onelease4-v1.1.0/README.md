# ISC Kea Hooks

Documentation for Kea and hooks:

- https://jenkins.isc.org/job/Kea_doc/doxygen/
- https://jenkins.isc.org/job/Kea_doc/doxygen/df/d46/hooksdgDevelopersGuide.html
- https://jenkins.isc.org/job/Kea_doc/doxygen/de/df3/dhcpv4Hooks.html

## Kea ONElease4 Hook

### Version: `1.1.0`

This is quite a simple hook to assign ONE lease for a client based on its HW (MAC) address. It will work properly only if clients have HW addresses generated in a particular way: **the last four bytes represent an IPv4 address**

For example, let's have a client with this HW address:

```
02:00:c0:a8:e9:64
```

First two bytes must match the hook parameter `byte-prefix` (explained below - in this case: `02` and `00`) and the rest is interpretated like this:

- `c0` is hexadecimal for decimal: `192`
- `a8` is hexadecimal for decimal: `168`
- `e9` is hexadecimal for decimal: `233`
- `64` is hexadecimal for decimal: `100`

It means that the ONE lease will be: `192.168.233.100`

Of course the ONE lease must meet subnet and pool constraints first...

### Installation

You will first need to have installed [**ISC Kea**](https://www.isc.org/kea/) software **with** header/development packages (so the hook can link against it) - or use [**`addon-kea-hooks`**](https://github.com/OpenNebula/addon-kea-hooks) parent project (this very repo) and have all in one.

You can modify the build by editing the `Makefile.config` but there is not so many tweakable things to do except changing the name of the hook library, output directory and compiler flags (the names of the linked libraries might be in the need of fixing too - the ones used here are matching the installation on the Alpine Linux).

After that you simply run `make`:

```
% make
```

If everything went fine then you should see the compiled library in the `build` directory:

```
% ls -l build
```

And copy the library file into your Kea hook directory or just *install* it:

```
% make install
```

### Usage

To enable and use this hook - insert similar json under `hooks-libraries` in your [config](https://kea.readthedocs.io/en/v1_6_0/arm/hooks.html#configuring-hooks-libraries):

```
"hooks-libraries": [
    ...
    {
        "library": "/opt/kea/lib/kea/hooks/libkea-onelease-dhcp4.so",
        "parameters": {
            "enabled": true,
            "byte-prefix": "00:02",
            "subnets": ["192.168.233.0/24", "10.1.0.0/16"],
            "logger-name": "onelease-dhcp4",
            "debug": true,
            "debug-logfile": "/var/log/onelease-dhcp4-debug.log"
        }
    }
    ...
]
```

**All parameters are optional** - so you can just use:

```
{
    "library": "/opt/kea/lib/kea/hooks/libkea-onelease-dhcp4.so"
}
```

#### Hook parameters

- `enabled` (`boolean`) - enable/disable the function of this hook
- `byte-prefix` (`string`) - hexadecimal representation of the first two bytes in HW address
- `subnets` (`list`) - list of subnets in CIDR (hook applies only to these clients)
- `logger-name` (`string`) - identification in the debug log
- `debug` (`boolean`) - enable/disable the debug log
- `debug-logfile` (`string`) - filename for the debug log

`byte-prefix` and `subnets` are basically conditionals - they must be both true **or** the **normal** lease procedure will take place. **If they are NOT defined then it is like they are always true.** They give us better control to select which packets this hook should handle and which packets should be processed normally.

### OpenNebula

The motivation for this hook is from OpenNebula's VNFs appliance requirement: assign IPv4 address (via DHCP) from MAC address value.

OpenNebula generates MAC addresses for VM's network interfaces in a particular way. Every virtual interface is assigned to some specific network with specific subnet/range. By default there is no DHCP service but OpenNebula assigns (internally) some (mostly the lowest unassigned) valid IPv4 from this range regardless and if the user enables the `NETWORK CONTEXT` then OpenNebula will setup VM with this static address.

Part of this internal IPv4 assignment is also the creation of a matching MAC address. By matching I mean that the last four bytes in MAC address equal to the four bytes representing the IPv4 address.

So if you create VM with the interface attached to a OpenNebula's network:

```
192.168.233.0/24
```

with an ip range pool of:

```
192.168.233.100 - 192.168.233.200
```

then OpenNebula assigns this interface the IPv4 address (by being the first):

```
192.168.233.100
```

and the generated MAC address will be:

```
02:00:c0:a8:e9:64
```

*Note: To see how the MAC address relates to IP look above in the intro.*

The point of this hook is to honor this inner working of OpenNebula to not confuse users and for VMs to have a convenient and predicable dynamic addresses...

