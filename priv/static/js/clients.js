const PATH_CLIENT = "admin/client";
const PATH_LDAP_AREA = "admin/client_ldap_area";

function add_field(description, id, value, box){
    let description_element = document.createElement('b');
    description_element.appendChild(document.createTextNode(description));
    let field = document.createElement('input');
    field.classList.add(id)
    field.value = value
    field.type = "text"

    box.appendChild(description_element);
    box.appendChild(field)
    box.appendChild(document.createElement('br'));

    return field;
}

function notify(text){
    element = document.getElementById('notifications');
    removeAllChildNodes(element);
    element.appendChild(document.createTextNode(text));
}

function edit(clientid){
    element = document.getElementById('client-'+String(clientid));
    name_field = element.querySelector('.name');
    url_field = element.querySelector('.url');

    body = {
        'name': name_field.value,
        'url': url_field.value
    }

    apiCall(PATH_CLIENT+"/"+String(clientid), PUT, body, function(res){
        notify("Client application updated");
        load();
    }, function(res, status){
        if(status==409){
            notify("There was a conflict updating this application: " + String(res));
        }
        if(status==403){
            window,location.replace('login.html?redirect=clients.html')
        }
    });
}

function load(){
    apiCall(PATH_CLIENT, GET, null, function(res){
        list = document.getElementById('clients_list');
        removeAllChildNodes(list);

        res.forEach(function(item){
            element = document.createElement('li');
            element.id='client-'+String(item.id);

            type_description = document.createElement('b');
            type_description.appendChild(document.createTextNode('Type: '));
            element.appendChild(type_description);
            type_field = document.createElement('span');
            type_field.appendChild(document.createTextNode(item.type));
            element.appendChild(type_field);
            element.appendChild(document.createElement('br'));

            id_description = document.createElement('b');
            element.appendChild(id_description);
            id_field = document.createElement('span');
            id_field.appendChild(document.createTextNode(item.id));
            if(item.type == "ldap"){
                id_field.classList.add("ldapClient");
                id_description.appendChild(document.createTextNode('Bind DN: '));
            }else{
                id_description.appendChild(document.createTextNode('Id: '));
            }
            element.appendChild(id_field);
            element.appendChild(document.createElement('br'));

            name_field = add_field("Name: ", 'name', item.name, element);
            onEnter(name_field, function(){
                edit(item.id)
            });

            let url_field;
            switch(item.type){
                case "forward":
                    url_field = add_field("Domain: ", 'url', item.url, element);
                    break;
                case "proxy":
                    url_field = add_field("Proxy to: ", 'url', item.url, element);
                    break;
                default:
                    url_field = add_field("URL: ", 'url', item.url, element);
            }
            onEnter(url_field, function(){
                edit(item.id)
            });


            if(item.type === "oauth"){
                callbacks = document.createElement('div');
                callbacks.classList.add("callback_uris");
                element.appendChild(callbacks);
                load_callbacks(item.id, callbacks);
            }

            edit_button = document.createElement('button');
            edit_button.appendChild(document.createTextNode('Edit Data'));
            element.appendChild(edit_button);
            edit_button.addEventListener("click", function(){edit(item.id);});
            
            secret_button = document.createElement('button');
            secret_button.appendChild(document.createTextNode('View credentials'));
            secret_button.addEventListener("click", function(){view_credentials(item.id);});
            element.appendChild(secret_button);

            delete_button = document.createElement('button');
            delete_button.appendChild(document.createTextNode('Delete'));
            delete_button.addEventListener("click", function(){delete_client(item.id);});
            element.appendChild(delete_button);

            list.appendChild(element);
        });
    }, function(res, status){
        if(status == 403){
            window.location.replace('login.html?redirect=clients.html');
        }else{
            notify("Error when loading: " + String(res));
        }
    });
}

function load_ldapArea(){
    apiCall(PATH_LDAP_AREA, GET, null, function(res){
        style = document.querySelector('style#js');
        style.innerHTML = ".ldapClient:before { content: \"id=\"; } .ldapClient:after { content: \"," + res + "\"; }"
    })
}

function load_callbacks(client_id, element){
    apiCall(PATH_CLIENT+"/"+client_id+"/callbacks", GET, null, function(res){
        removeAllChildNodes(element);

        let title = document.createElement('b')
        title.appendChild(document.createTextNode("Callback URIs:"))
        element.appendChild(title)
        element.appendChild(document.createElement('br'))
        let ul = document.createElement('ul');
        res.forEach(function(callback){
            let li = document.createElement('li');
            li.appendChild(document.createTextNode(callback))
            li.appendChild(document.createTextNode("\u00A0\u00A0\u00A0\u00A0")); //add some whitespace
            let button = document.createElement('button');
            button.appendChild(document.createTextNode("delete"));
            button.addEventListener("click", function(){delete_callback(client_id, callback, li)});
            li.appendChild(button);

            ul.appendChild(li)
        });
        element.appendChild(ul);

        let field = document.createElement('input');
        field.type = 'text';
        field.placeholder = 'Callback URI';
        element.appendChild(field);

        let button = document.createElement('button');
        button.appendChild(document.createTextNode("Add new Callback URI"));
        button.addEventListener("click", function(){add_callback(client_id, field, element);});
        element.appendChild(button);

    }, function(status, msg){
        notify("Failed loading callbacks for " + client_id + ": " + msg)
    });
}

function add_callback(client_id, field, element){
    body = {
        "uri": field.value
    }
    apiCall(PATH_CLIENT+"/"+client_id+"/callbacks", POST, body, function(res){
        notify("Added Callback URL");
        load_callbacks(client_id, element);
    }, function(msg, status){
        notify("Error adding callback URL: " + msg)
    });
}

function delete_callback(client_id, uri, element){
    body = {
       "uri": uri
    }
    apiCall(PATH_CLIENT+"/"+client_id+"/callbacks", DELETE, body, function(res){
        element.remove()
    }, function(status, msg){
        notify("Failed removing callback " + uri + " for " + client_id + ": " + msg)
    });
}

function create_client(){
    name_field = document.getElementById("name");
    type_field = document.getElementById("type");
    url_field = document.getElementById("url");

    body = {
        'name': name_field.value,
        'type': type_field.value,
        'url': url_field.value
    }
    apiCall(PATH_CLIENT, POST, body, function(res){
        notify("Created client");
        load();
    }, function(res, status){
        if(status == 403){
            window.location.replace("login.html?redirect=clients.html");
        }else{
            notify("Error creating client: " + String(res));
        }
    });
}

function delete_client(id){
    apiCall(PATH_CLIENT+"/"+String(id), DELETE, null, function(res){
        notify("Deleted client");
        load();
    }, function(res, status){
        if(status===403){
            window.location.replace("login.html?redirect=clients.html");
        }else{
            notify("Error deleting user: " + String(res))
        }
    });
}

function view_credentials(id){
    apiCall(PATH_CLIENT+"/"+String(id)+"/credentials", GET, null, function(res){
        notify("Secret for this application: " + res.secret)
    }, function(res, status){
        if(status===403){
            window.location.replace("login.html?redirect=clients.html")
        }else{
            notify("Error retrieving credentials: " + String(res))
        }
    });
}

function set_url_placeholder(){
    let type_field = document.getElementById("type");
    let url_field = document.getElementById("url");

    let value = type_field.value
    switch(value){
        case "forward":
            url_field.placeholder = "Service Domain";
            break;
        case "proxy":
            url_field.placeholder = "Adress to proxy to";
            break;
        default:
            url_field.placeholder = "URL";
    }
}



document.addEventListener("DOMContentLoaded", function(event) {
    name_field = document.getElementById("name");
    onEnter(name_field, create_client);

    document.getElementById("create_client").addEventListener("click", create_client);
    document.getElementById("type").addEventListener("change", set_url_placeholder);

    load_ldapArea();

    load();
});

