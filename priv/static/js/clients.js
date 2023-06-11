const PATH_CLIENT = "admin/client";
const PATH_LDAP_AREA = "admin/client_ldap_area";

function add_field(description, value_name, value, box, item_id, disabled=false){
    let description_element = document.createElement('label');
    description_element.for = 'client-'+item_id+'-'+value_name;
    description_element.id = description_element.for+'-label';
    description_element.appendChild(document.createTextNode(description));
    let field = document.createElement('input');
    field.id = 'client-'+item_id+'-'+value_name;
    field.classList.add(value_name)
    field.classList.add('pure-input');
    field.classList.add('pure-input-1');
    field.value = value
    field.type = "text"
    if(disabled){
        field.readOnly = true;
    }

    box.appendChild(description_element);
    box.appendChild(field)

    return field;
}

function edit(clientid){
    let element = document.getElementById('client-'+String(clientid));
    let name_field = element.querySelector('.name');
    let url_field = element.querySelector('.url');
    let destination_field = element.querySelector('.destination');

    let body = {
        'name': name_field.value,
        'url': url_field.value
    }
    if(destination_field !== null){
        body.destination = destination_field.value;
    }

    apiCall(PATH_CLIENT+"/"+String(clientid), PUT, body, function(res){
        Jackbox.success("Client application updated");
        load();
    }, function(res, status){
        if(status==409){
            Jackbox.error("There was a conflict updating this application: " + String(res));
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
            element.classList.add('pure-form');
            element.classList.add('pure-form-aligned');
            element.id='client-'+String(item.id);

            add_field('Type', 'type', item.type, element, item.id, true);
            if(item.type == "ldap"){
                let field = add_field('Bind DN', 'id', item.id, element, item.id, true);
                field.classList.add('ldap_dn');
                if("ldapArea" in globalThis){
                    field.value = "id="+field.value+","+globalThis.ldapArea;
                }
            }else if(item.type == "oauth"){
                add_field('Client Id', 'id', item.id, element, item.id, true);
            }

            name_field = add_field("Name", 'name', item.name, element, item.id);
            onEnter(name_field, function(){
                edit(item.id)
            });

            let url_field;
            switch(item.type){
                case "forward":
                    url_field = add_field("Domain", 'url', item.url, element, item.id);
                    break;
                case "proxy":
                    url_field = add_field("Domain", 'url', item.url, element, item.id);
                    break;
                default:
                    url_field = add_field("URL", 'url', item.url, element, item.id);
            }
            onEnter(url_field, function(){
                edit(item.id)
            });

            if(item.type === "proxy"){
                let destination_field = add_field("Proxy destination", 'destination', item.destination, element, item.id);
                onEnter(destination_field, function(){
                    edit(item.id)
                });
            }

            if(item.type === "oauth"){
                callbacks = document.createElement('div');
                callbacks.classList.add("callback_uris");
                element.appendChild(callbacks);
                load_callbacks(item.id, callbacks);
            }

            let button_group = document.createElement('button-group');
            button_group.role = 'group';
            button_group.classList.add('pure-button-group');

            let edit_button = document.createElement('button');
            edit_button.appendChild(document.createTextNode('Edit Data'));
            edit_button.classList.add('pure-button');
            edit_button.classList.add('pure-button-primary');
            button_group.appendChild(edit_button);
            edit_button.addEventListener("click", function(){edit(item.id);});
            
            if(item.type == 'oauth' || item.type == 'ldap'){
                let secret_button = document.createElement('button');
                secret_button.appendChild(document.createTextNode('View credentials'));
                secret_button.classList.add('pure-button');
                secret_button.id = 'client-'+item.id+'-secret_button';
                secret_button.addEventListener("click", function(){view_credentials(item.id);});
                button_group.appendChild(secret_button);
            }

            let delete_button = document.createElement('button');
            delete_button.appendChild(document.createTextNode('Delete'));
            delete_button.classList.add('pure-button');
            delete_button.classList.add('button-delete');
            delete_button.addEventListener("click", function(){delete_client(item.id);});
            button_group.appendChild(delete_button);
    
            element.appendChild(button_group);
            list.appendChild(element);
        });
    }, function(res, status){
        if(status == 403){
            window.location.replace('login.html?redirect=clients.html');
        }else{
            Jackbox.error("Error when loading: " + String(res));
        }
    });
}

function load_ldapArea(){
    if("ldapArea" in globalThis){
        apply_ldapArea(globalThis.ldapArea)
    }else{
        apiCall(PATH_LDAP_AREA, GET, null, function(res){
            globalThis.ldapArea=res;
            apply_ldapArea(res);
        })
    }
}

function apply_ldapArea(area){
    let elements = document.getElementsByClassName('ldap_dn');
    for(let el of elements){
        el.value = "id="+el.value+","+area;
    }
}


function load_callbacks(client_id, element){
    apiCall(PATH_CLIENT+"/"+client_id+"/callbacks", GET, null, function(res){
        removeAllChildNodes(element);

        let title = document.createElement('b')
        title.appendChild(document.createTextNode("Callback URIs"))
        element.appendChild(title)
        element.appendChild(document.createElement('br'))
        let ul = document.createElement('div');
        ul.classList.add('pure-g');
        res.forEach(function(callback){
            let div_1 = document.createElement('div');
            div_1.classList.add('pure-u-2-3');
            div_1.classList.add('pure-u-md-4-5');
            let input = document.createElement('input');
            input.type = 'text';
            input.classList.add('pure-input');
            input.classList.add('pure-input-1');
            input.value = callback;
            input.readOnly = true;
            div_1.appendChild(input)
            let div_2 = document.createElement('div');
            div_2.classList.add('pure-u-1-3');
            div_2.classList.add('pure-u-md-1-5');
            let button = document.createElement('button');
            button.appendChild(document.createTextNode("Delete"));
            button.classList.add('pure-button');
            button.classList.add('button-delete');
            button.style = 'width: 100%';
            button.addEventListener("click", function(){delete_callback(client_id, callback, li)});
            div_2.appendChild(button);

            ul.appendChild(div_1);
            ul.appendChild(div_2);
        });
        element.appendChild(ul);

        let field_div = document.createElement('div');
        field_div.classList.add('pure-u-2-3');
        field_div.classList.add('pure-u-md-4-5');
        let field = document.createElement('input');
        field.type = 'text';
        field.classList.add('pure-input');
        field.classList.add('pure-input-1');
        field.placeholder = 'Callback URI';
        field_div.appendChild(field);

        let button_div = document.createElement('div');
        button_div.classList.add('pure-u-md-1-5');
        let button = document.createElement('button');
        button.appendChild(document.createTextNode("Add"));
        button.classList.add('pure-button');
        button.classList.add('pure-button-primary');
        button.style = 'width: 100%;';
        button.addEventListener("click", function(){add_callback(client_id, field, element);});
        button_div.appendChild(button);

        element.appendChild(field_div);
        element.appendChild(button_div);

    }, function(status, msg){
        Jackbox.error("Failed loading callbacks for " + client_id + ": " + msg)
    });
}

function add_callback(client_id, field, element){
    body = {
        "uri": field.value
    }
    apiCall(PATH_CLIENT+"/"+client_id+"/callbacks", POST, body, function(res){
        Jackbox.success("Added Callback URL");
        load_callbacks(client_id, element);
    }, function(msg, status){
        Jackbox.error("Error adding callback URL: " + msg)
    });
}

function delete_callback(client_id, uri, element){
    body = {
       "uri": uri
    }
    apiCall(PATH_CLIENT+"/"+client_id+"/callbacks", DELETE, body, function(res){
        element.remove()
    }, function(status, msg){
        Jackbox.error("Failed removing callback " + uri + " for " + client_id + ": " + msg)
    });
}

function create_client(){
    let name_field = document.getElementById("name");
    let type_field = document.getElementById("type");
    let url_field = document.getElementById("url");

    let destination_field;
    if(type_field.value === "proxy"){
        destination_field = document.getElementById("destination");
    }else{
        destination_field = null;
    }

    let body = {
        'name': name_field.value,
        'type': type_field.value,
        'url': url_field.value
    }
    if(destination_field !== null){
        body.destination = destination_field.value
    }
    apiCall(PATH_CLIENT, POST, body, function(res){
        Jackbox.success("Created client");
        load();
    }, function(res, status){
        if(status == 403){
            window.location.replace("login.html?redirect=clients.html");
        }else{
            Jackbox.error("Error creating client: " + String(res));
        }
    });
}

function delete_client(id){
    apiCall(PATH_CLIENT+"/"+String(id), DELETE, null, function(res){
        Jackbox.success("Deleted client");
        load();
    }, function(res, status){
        if(status===403){
            window.location.replace("login.html?redirect=clients.html");
        }else{
            Jackbox.error("Error deleting user: " + String(res))
        }
    });
}

function view_credentials(id){
    apiCall(PATH_CLIENT+"/"+String(id)+"/credentials", GET, null, function(res){
        let client_name_field = document.getElementById('client-'+id+'-name-label');
        let client_form = client_name_field.parentElement;
        let secret_label = document.createElement('label');
        secret_label.for = 'client-'+id+'-secret';
        secret_label.appendChild(document.createTextNode('Secret'));
        client_form.insertBefore(secret_label, client_name_field);
        let secret_field = document.createElement('input');
        secret_field.id = 'client-'+id+'-secret';
        secret_field.classList.add('pure-input');
        secret_field.classList.add('pure-input-1');
        secret_field.value = res.secret;
        secret_field.readOnly = true;
        client_form.insertBefore(secret_field, client_name_field);

        let secret_button = document.getElementById('client-'+id+'-secret_button');
        secret_button.classList.add('pure-button-disabled');
        
    }, function(res, status){
        if(status===403){
            window.location.replace("login.html?redirect=clients.html")
        }else{
            Jackbox.error("Error retrieving credentials: " + String(res))
        }
    });
}

function set_url_placeholder(){
    let type_field = document.getElementById("type");
    let url_label = document.getElementById("url_label");

    let value = type_field.value
    switch(value){
        case "forward":
            removeAllChildNodes(url_label);
            url_label.appendChild(document.createTextNode("Service Domain"));
            break;
        case "proxy":
            removeAllChildNodes(url_label);
            url_label.appendChild(document.createTextNode("Service Domain"));
            break;
        default:
            removeAllChildNodes(url_label);
            url_label.appendChild(document.createTextNode("URL"));
    }

    let form = document.getElementById("form");
    if(value === "proxy"){
        let destination_label = document.createElement("label");
        destination_label.for = "destination";
        destination_label.appendChild(document.createTextNode("Address to proxy to, in full"));
        destination_label.id = "destination_label";
        let destination_field = document.createElement("input");
        destination_field.type = "text";
        destination_field.id = "destination";
        destination_field.classList.add('pure-input');
        destination_field.classList.add('pure-input-1');

        let type_label = document.getElementById("type_label");
        form.insertBefore(destination_label, type_label);
        form.insertBefore(destination_field, type_label);
    }else{
        let destination_field = document.getElementById("destination");
        if(destination_field != null){
            destination_field.remove();
            let destination_label = document.getElementById("destination_label");
            destination_label.remove();
        }
    }
}



document.addEventListener("DOMContentLoaded", function(event) {
    Jackbox.init()

    name_field = document.getElementById("name");
    onEnter(name_field, create_client);

    document.getElementById("create_client").addEventListener("click", create_client);
    document.getElementById("type").addEventListener("change", set_url_placeholder);

    load_ldapArea();

    load();

    set_url_placeholder();
});

