const PATH_USER = "admin/user";
const PATH_LOGOUT = "session/logout";

function add_field(description, value_name, value, box, element_id, disabled=false){
    let description_element = document.createElement('label');
    description_element.for = "user-"+element_id+"-"+value_name;
    description_element.appendChild(document.createTextNode(description));
    let field = document.createElement('input');
    field.id = "user-"+element_id+"-"+value_name;
    field.classList.add(value_name)
    field.classList.add('pure-input');
    field.classList.add('pure-input-1');
    field.value = value;
    field.type = "text";
    if(disabled){
        field.readOnly = true;
    }

    box.appendChild(description_element);
    box.appendChild(field)

    return field;
}

function edit(userid){
    element = document.getElementById('user-'+String(userid));
    email_field = element.querySelector('.email');
    name_field = element.querySelector('.name');
    admin_field = element.querySelector('.admin');

    body = {
        'email': email_field.value,
        'name': name_field.value,
        'admin': admin_field.checked
    }

    apiCall(PATH_USER+"/"+String(userid), PUT, body, function(res){
        Jackbox.success("User updated");
        load();
    }, function(res, status){
        if(status==409){
            Jackbox.error("There was a conflict updating this user: " + String(res));
        }
        if(status==403){
            window,location.replace('login.html?redirect=users.html')
        }
    });
}

function change_password(userid){
    apiCall(PATH_USER+"/"+String(userid)+"/change_password", PUT, null, function(res){
        Jackbox.success("Changed user password: new password is " + res.password);
    }, function(res, status){
        if(status===403){
            window.location.replace("login.html?redirect=users.html");
        }else{
            Jackbox.error("Error updating password: " + String(res));
        }
    });
}

function load(){
    apiCall(PATH_USER, GET, null, function(res){
        list = document.getElementById('users_list');
        removeAllChildNodes(list);

        res.forEach(function(item){
            element = document.createElement('li');
            element.classList.add('pure-form');
            element.classList.add('pure-form-stacked');
            element.id='user-'+String(item.id);

            add_field("Id", 'id', item.id, element, item.id, true);
            add_field("Username", 'username', item.username, element, item.id, true);
            email_field = add_field("Email", 'email', item.email, element, item.id);
            onEnter(email_field, function(){
                edit(item.id)
            });
            name_field = add_field("Name", 'name', item.name, element, item.id);
            onEnter(name_field, function(){
                edit(item.id)
            });

            admin_description = document.createElement('label');
            admin_box = document.createElement('input');
            admin_box.type = 'checkbox';
            admin_box.classList.add('admin');
            if(item.admin){
                admin_box.checked = true;
            }
            admin_description.appendChild(admin_box);
            admin_description.appendChild(document.createTextNode(' Admin'));
            element.appendChild(admin_description);

            let button_group = document.createElement('div');
            button_group.role = "group";
            button_group.classList.add('pure-button-group');

            let edit_button = document.createElement('button');
            edit_button.appendChild(document.createTextNode('Edit Data'));
            edit_button.classList.add('pure-button');
            edit_button.classList.add('pure-button-primary');
            button_group.appendChild(edit_button);
            edit_button.addEventListener("click", function(){edit(item.id);});
            
            let password_button = document.createElement('button');
            password_button.appendChild(document.createTextNode('Change Password'));
            password_button.addEventListener("click", function(){change_password(item.id);});
            password_button.classList.add('pure-button');
            button_group.appendChild(password_button);

            let delete_button = document.createElement('button');
            delete_button.appendChild(document.createTextNode('Delete'));
            delete_button.addEventListener("click", function(){delete_user(item.id);});
            delete_button.classList.add('pure-button');
            delete_button.classList.add('button-delete');
            button_group.appendChild(delete_button);

            element.appendChild(button_group);
            list.appendChild(element);
        });
    }, function(res, status){
        if(status == 403){
            window.location.replace('login.html?redirect=users.html');
        }else{
            Jackbox.error("Error when loading: " + String(res));
        }
    });
}

function create_user(){
    username_field = document.getElementById("username");
    email_field = document.getElementById("email");
    name_field = document.getElementById("name");
    admin_field = document.getElementById("admin");
    password_field = document.getElementById("password");
    confirm_field = document.getElementById("confirm");


    if(password_field.value !== confirm_field.value){
        Jackbox.warning("Passwords do not match");
    }else{
        body = {
            'username': username_field.value,
            'email': email_field.value,
            'name': name_field.value,
            'admin': admin_field.checked,
            'password': password_field.value
        }
        apiCall(PATH_USER, POST, body, function(res){
            Jackbox.success("Created user");
            load();
        }, function(res, status){
            if(status == 403){
                window.location.replace("login.html?redirect=users.html");
            }else{
                Jackbox.error("Error creating user: " + String(res));
            }
        });
    }
}

function delete_user(id){
    apiCall(PATH_USER+"/"+String(id), DELETE, null, function(res){
        Jackbox.success("Deleted user");
        load();
    }, function(res, status){
        if(status===403){
            window.location.replace("login.html?redirect=users.html");
        }else{
            Jackbox.error("Error deleting user: " + String(res))
        }
    });
}

function logout(){
    apiCall(PATH_LOGOUT, POST, null, function(res){
        window.location.replace("login.html");
    }, function(status, res){
        if(status == 403){
            window.location.replace("login.html?redirect=index.html");
        }else{
            alert("Unknown error logging out: " + String(res))
        }
    });
}

document.addEventListener("DOMContentLoaded", function(event) {
    Jackbox.init();

    username_field = document.getElementById("username");
    email_field = document.getElementById("email");
    name_field = document.getElementById("name");
    password_field = document.getElementById("password");
    confirm_field = document.getElementById("confirm");

    onEnter(username_field, create_user);
    onEnter(email_field, create_user);
    onEnter(name_field, create_user);
    onEnter(password_field, create_user);
    onEnter(confirm_field, create_user);

    let logout_link = document.getElementById('logout-menu');
    logout_link.addEventListener("click", logout);

    document.getElementById("create_user").addEventListener("click", create_user);

    load();
});

