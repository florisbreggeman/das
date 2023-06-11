# Das

The domestic authentication service, or DAS for short (name pending) is an authentication service specifically designed for domestic self-hosting.
This means it supports the maximum variety of client applications, while including the minimum amount of enterprise functionality.

It supports client applications via OAuth, LDAP, and Authelia-style reverse proxy authentication.
The project is written in Elixir, which means it should use relatively few resources, and more importantly remain available even under very high load.

## Acknowledgements

This software uses the [Pure CSS library](purecss.io) for CSS rendering and the [Jackbox javascript library](https://github.com/ja1984/jackbox) is used to provide notifications. The licences for these projects have been placed in the licences folder.

Please note that the Jackbox library is licenced under GPL. If you wish to redistribute DAS without adhering to GPL, replacing it with a different notifications library is recommended.

## Installation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/das>.

