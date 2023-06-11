# How to use Reverse-proxy authentication with Nginx.

In order to use the reverse-proxy authentication method with Nginx, we can use the forward auth method.
In this method, Nginx first forwards the request to DAS before sending it along to the client application.
If DAS determines the request is not authenticated, Nginx will refuse to show the webpage, and if properly configured, redirect the user to DAS to authenticate.
If DAS can authenticate the user, the username and email of the user are communicated to the client application in the `Remote-User` and `Remote-Email` headers respectively.

This folder contains some snippets that help with configuring Nginx for your client application, as well as some examples for each application.
It is recommended you copy all snippets in the `snippets` folder to your `/etc/nginx/snippets`.
The `das_location` snippets includes the location of your DAS instance; please make sure to change this to the location where DAS is running on your system.

Which file you want to use is dependent on how Nginx communicates with the service you are protecting.
If this communication goes over normal HTTP proxying, consult proxy\_pass.conf.
If this communication goes over FastCGI, which is most commmonly used for PHP, consult fastcgi.conf.

