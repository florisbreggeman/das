# ASN.1 folder

LDAP uses a binary wire protocol.
The syntax of this protocol is defined in ASN.1, a language for defining binary protocols in a language-independent way.
There exists a compiler to turn ASN.1 syntax into a file with encoder and decoder source code, which can be found in the erlang module `asn1ct`.
Fortunately for me, the eldap module (part of OTP) already has both the syntax and the header files, which themselves are enough to compile a full encoder and decoder.
These files can be found in this folder.

Compiling these files can be done by opening `iex` and running `:asn1ct.compile('ELDAPv3.asn1', [ber: true])` (or doing a similar call in `erl`).
This will result in a `ELDAPv3.asn1db` and `ELDAPv3.erl`, the latter of which exports a module that contains the module.
These files can be found under another name in `ldap_asn/src`, where they are part of the project.

Technically speaking, it's also possible to compile this project without including the source compiler, as the `eldap` library, and as such the `ELDAPv3` module, are part of OTP.
However, I do not feel comfortable shipping software that assumes this code will be available in OTP on all systems forever.

