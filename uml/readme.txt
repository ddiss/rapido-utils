run uml/vm.sh to boot the rapido VM as a User-Mode Linux process.

Notes:

# CONFIG_UML_RANDOM breaks network support
  -> also requires rng-utils (should work like libvirt's driver)

I haven't been able to get pty console redirection working yet

mgmt console (mconsole) requires separate utility

aarch64 not supported
- see aaeac66b1a02d399ec8ee63e8d617c1d601ea353 (ppc removal)
- http://user-mode-linux.sourceforge.net/old/arch-port.html
