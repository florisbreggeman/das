#LDAP ASN library

LDAP uses a binary syntax which is based on ASN.1.
This project ships with a decoder/encoder library for this syntax, which was generated from the actual ASN.1 syntax, using files from the OTP module `eldap`.
See the `asn1` folder for how this was done.

Because the resulting code is in erlang, and not elixir, it needs to be in a separate project.
This folder contains a rebar3 project, which is the erlang equivalent of mix.
The main project then imports it as a library from source.

