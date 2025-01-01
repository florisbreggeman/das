# Das

The domestic authentication service, or DAS for short is an authentication service specifically designed for domestic self-hosting.
This means it supports the maximum variety of client applications, while including the minimum amount of enterprise functionality.

It supports client applications via OAuth, LDAP, Authelia-style forward authentication, as well as proxy-style authentication in case forward authentication is desired under the Apache reverse proxy.
The project is written in Elixir, which means it should use relatively few resources, and more importantly remain available even under very high load.

## Features

 - Provides single sign-on authentication via OAuth2
 - Provides single sign-on authentication via forward authentication
 - Provides single sign-on authentication via proxy authetication (as an alternative to forward authentication)
 - Users can be authenticated via LDAP
 - Optional TOTP 2-factor authentication
 - Very simple interface
 - Lightweight runtime and front-end

## Installation

To install DAS:

 - Download a release from your operating system from the release page to a target folder of your choice, e.g. `/opt/das`, and enter this directory (we will call this the root directory)
 - Review the runtime configuration in `releases/1.0/runtime.exs` to see if there are any settings you would like to change
   - Most notably, you probably want to change the `default_` settings to ensure the initial user it to your liking
   - Note the configuration file is in Elixir syntax, backslashes need to be escaped.
 - Review the configuration settings in `config/runtime.exs` to see if there's anything you would like to change
 - It is recommended you make a new user and group by running `useradd -U -b <root dir> das` 
   - You must then also change the ownership of the folder by running `chown -R das:das .`
 - To start DAS, run `/bin/das start` as the `das` user
   - This will create an initial user using the specifications in `releases/1.0/runtime.exs`
 - To install DAS as a deamon under systemd, ensure the `WorkingDirectory` in `das.service` is correct; if so, run `cp das.service /lib/systemd/system/` followed by `systemctl daemon-reload; systemctl enable das.service`.
 - For security reasons, it is highly recommend to, after the first startup, edit `releases/1.0/runtime.exs` to set the `default_add` value to false

### Reverse-proxy configuration

As DAS does not natively handle TLS, the use of a reverse-proxy which does is mandatory for OAuth2 and highly recommended for the use of all other protocols.
A reverse proxy only needs to proxy-forward requests to DAS web port, and DAS will handle the rest.
Optionally, speed can be improved by statically serving the files in `<root dir>/lib/das-1-0-0/priv/static`.

See the example Nginx configuration below:

```
server {
    listen [::]:443 ssl;
    listen 443 ssl;
    server_name das.example.com;
    root /opt/das/lib/das-1.0.0/priv/static;
    location ~ .*\.(html|css|js) {
        try_files $uri $uri/ =404;
    }
    location /{
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:8080;
    }
}
```

### In case there is no release for your operating system

If there's no release for your operating system, you will have to compile one yourself.
Don't worry; this is not as difficult as it might seem.
If you don't want to install unneeded software directly onto your system, it is possible to compile the software in a container or VM and move the compiled files to your actual machine.

 - [Install the elixir software for your operating system](https://elixir-lang.org/install.html). 
   - If there is no Elixir library available for your operating system, you may want to check out [Erlang Solutions](https://www.erlang-solutions.com/downloads/https://www.erlang-solutions.com/downloads/). You could also install an erlang library, and [compile Elixir from source](https://github.com/elixir-lang/elixir).
 - Clone this project into a directory of your choice that is not the directory that you want to run it in (such as your home directory), and change into the project folder
 - Run `mix deps.get` (this requires an internet connection)
 - Run `cp config/runtime.exs.example config/runtime.exs`, and check any settings in `config/runtime.exs`
 - Run `MIX_ENV=prod mix release das` (this may take a few minutes)
 - A release has just been created in `_build/prod/rel/das`. You probably want to copy these files to your target directory.

### Docker support

A `Dockerfile` is provided in the `docker` directory of this repo, along with an example `docker-compose.yml`. It uses environment variables as specified in `config/runtime.exs.docker`
so it is easiest to look at that to see what is supported.

## Usage

### Basic functionality

The normal page gives you the ability to change your name and password.
Your email address can't be changed, to prevent issues with services that (incorrectly) assume email addresses never change.
You can also enable two-factor authentication, which will display a QR code; scan this QR code in your authentication app of choice (I personally use the Lastpass authenticator).
After you have enabled TOTP, you will have to enter the TOTP code on login.

### User Administration

Administrators can add and edit users from the users panel.
Administrators can also set the users password; please note that for security reasons, you can only reset somebody ele's password to a randomly generated one.
Also note that there must always be one administrator.

### Configuring client applications

Client applications are the applications that you want to log in to using DAS.
They can be configured using the applications panel.
DAS supports four different protocols for interacting with a client application: OAuth2, LDAP, forward authentication, and proxy authentication.
Although all client applications reside in the same location in the DAS interface and all behave similarly within DAS, you will have to take different steps depending on the type of your client application.

#### OAuth client applications

OAuth2 is the preferred protocol, as it allows for single sign-on, but only has one interaction with DAS.
In Oauth2, the client application redirects the user to DAS, which will redirect authenticated users back with a token that the client application can use to fetch the identity of the user.

For Oauth, both the name and URL values are cosmetic.
After creating an OAuth client application, you will be able to view the application id and secret.
You can then configure these in your OAuth client application.
You can use the following configuration for an OAuth client application:

 - **Client Id**: shown in DAS
 - **Clietn Secret**: shown in DAS (after pressing the "view credentials" button)
 - **Configuration**: https://<address>/.well-known/openid-configuration
 - **Authorization URL**: https://<address>/oauth/authorize
 - **Token URL**: https://<address>/oauth/token
 - **Userinfo endpoint**: https://<address>/oauth/userinfo

For security reasons, you must also configure the callback URIs with DAS; unrecognised callback URIs are not supported.
Unfortunately, many OAuth client applications don't show their callback URI.
As such, you may have to configure the application with the settings above, attempt to log in, and then add the callback URI shown in the subsequent error message to the client application.

#### LDAP Client applications

LDAP is an older protocol, where the client application sends the username/password directly to DAS to ask if they are correct.
While this is extremely simple and fast, it only allows for single credentials, but not for single sign-on; you will have to enter your password for every LDAP client application.

For LDAP Client Applications, both the name and URL are cosmetic.
You can use the following settings to configure an LDAP Client application:

 - **LDAP Url**: `ldap://localhost:3389` (running on the same machine, using default port setting)
 - **Bind DN**/**username**: shown in DAS
 - **Bind Secret**/**Password**: shown in DAS
 - **Search DN**: `ou=users,dc=das,dc=nl` (value not used by DAS; using default settings)
 - **objectClass**: `account` (value not used by DAS)
 - **filter**: `username=%v`
 - **name_field**: `username`
 - **email_field**: `email`
 - **protocol version**: 3
 - **TLS**: no

Note that the Search DN and objectClass are not actually checked for by DAS in any way, and as such you can probably fill in an arbitrary value.

#### Forward auth client applications

Forward auth is a simple protocol that is extremely easy to implement for client applications.
In forward auth, the reverse proxy checks each request with DAS to see if it is authenticated, and if it is, passes the username in a header to the client application.
This protocol allows for single sign-on, but is somewhat slower than Oauth, and can also lead to security vulnerabilities if not configured properly, especially if the client application and DAS are not running on the same machine.

For forward auth client applications, the URL **must** be set to the URL of the client application.
Furthermore, you must configure the reverse-proxy to use DAS for forward authentication.
Some example configuration files and instructions for Nginx can be found in `rproxy_config_files/nginx`.

For other reverse proxies, I recommend adapting the [Authelia documentation](https://www.authelia.com/integration/proxies/).
Take note that the location to forward requests to in DAS is `/forward_auth`
If you are using another reverse proxy and have configured it to use forward authentication with DAS, please make a pull request adding a generic form of your config files to the `rproxy_config_files` directory.

**NB**: it is extremely important that your client application can only be reached through the reverse proxy, and that each request is checked with DAS.
Furthermore, the reverse-proxy must not allow the `Remote-User` or `Remote-Email` header to pass from the incoming request to the client application; otherwise, an attacker could impersonate any user.

Please note that forward auth is completely unsupported under Apache due to lack of the forward authentication feature in Apache.
If you are using Apache in combination with apps that require forward auth, please check out Proxy auth.


#### Proxy authentication

Proxy authentication is an alternative to forward authentication that is agnostic of the ingress reverse-proxy.
In proxy authentication, DAS itself proxies all incoming requests to the client application, only letting through authenticated requests.
This is the only way to combine client applications that require forward auth with Apache.
It may also be more suitable for highly containerised systems, because it creates a clearer data path with less back-and-forth.

For proxy client applications, the Domain must correspond to the domain name of the client application.
Furthermore, proxy authentication requires a third value: the location where the client application can be reached, i.e. the location to send authenticated requests to.
This value must be full qualified including the protocol, e.g. `http://localhost:9000`.

**NB**: DAS may do some reverse proxying, and may even be able to distinguish between multiple services based on the domain name.
However, DAS is not a revers proxy, and notably does not support TLS.
As such, you **must** have another reverse proxy before the DAS proxy auth service.
Furthermore, as DAS is also not capable of serving static files or executing PHP scripts, you may have to point DAS towards a second internal reverse-proxy website.

**NB**: As with forward authentication, you must ensure that the client application can't be reached via the internet directly, as an attacker could impersonate any user!

### 2-Factor authentication and LDAP

DAS supports using TOTP 2-factor authentication over LDAP.
However, because in LDAP the client application is in charge of the login interface and unaware of the use of TOTP, this provides a suboptimal user experience.
TOTP over LDAP is disabled by default, and can be enabled by each user, by checking the setting at the bottom the 2-factor settings.
Note that this setting only appears once 2-factor authentication in general has been enabled.

When TOTP over LDAP is enabled, you must append your TOTP login code to your password when logging in to an LDAP application.
Unfortunately, it is impossible to communicate this to the end user at the login step.
If the login fails, it is also not possible to tell the user whether their password or TOTP code was incorrect.
Please note that each TOTP code can only be used once, i.e. you can only log in successfully every 30 seconds.

## Acknowledgements

This software uses the [Pure CSS library](purecss.io) for CSS rendering and the [Jackbox javascript library](https://github.com/ja1984/jackbox) is used to provide notifications. The licences for these projects have been placed in the licences folder.

Please note that the Jackbox library is licenced under GPL. If you wish to redistribute DAS without adhering to GPL, replacing it with a different notifications library is recommended.

## Installation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/das>.

