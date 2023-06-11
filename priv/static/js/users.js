const PATH_USER = "admin/user";

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

function edit(userid){
    element = document.getElementById('user-'+String(userid));
    email_field = element.querySelector('.email');
    given_names_field = element.querySelector('.given_names');
    family_name_field = element.querySelector('.family_name');
    admin_field = element.querySelector('.admin');

    body = {
        'email': email_field.value,
        'given_names': given_names_field.value,
        'family_name': family_name_field.value,
        'admin': admin_field.checked
    }

    apiCall(PATH_USER+"/"+String(userid), PUT, body, function(res){
        notify("User updated");
        load();
    }, function(res, status){
        if(status==409){
            notify("There was a conflict updating this user: " + String(res));
        }
        if(status==403){
            window,location.replace('login.html')
        }
    });
}

function change_password(userid){
    apiCall(PATH_USER+"/"+String(userid)+"/change_password", PUT, null, function(res){
        notify("Changed user password: new password is " + res.password);
    }, function(res, status){
        if(status===403){
            window.location.replace("login.html");
        }else{
            notify("Error updating password: " + String(res));
        }
    });
}

function load(){
    apiCall(PATH_USER, GET, null, function(res){
        list = document.getElementById('users_list');
        removeAllChildNodes(list);

        res.forEach(function(item){
            element = document.createElement('li');
            element.id='user-'+String(item.id);

            id_description = document.createElement('b');
            id_description.appendChild(document.createTextNode('Id: '));
            element.appendChild(id_description);
            id_field = document.createElement('span');
            id_field.appendChild(document.createTextNode(item.id));
            element.appendChild(id_field);
            element.appendChild(document.createElement('br'));

            username_description = document.createElement('b');
            username_description.appendChild(document.createTextNode('Username: '));
            element.appendChild(username_description);
            username_field = document.createElement('span');
            username_field.appendChild(document.createTextNode(item.username));
            element.appendChild(username_field);
            element.appendChild(document.createElement('br'));

            email_field = add_field("Email: ", 'email', item.email, element);
            onEnter(email_field, function(){
                edit(item.id)
            });
            given_names_field = add_field("Given Names: ", 'given_names', item.given_names, element);
            onEnter(given_names_field, function(){
                edit(item.id)
            });
            family_name_field = add_field("Family Name: ", 'family_name', item.family_name, element);
            onEnter(family_name_field, function(){
                edit(item.id)
            });

            admin_description = document.createElement('b');
            admin_description.appendChild(document.createTextNode('Admin: '));
            admin_box = document.createElement('input');
            admin_box.type = 'checkbox';
            admin_box.classList.add('admin');
            if(item.admin){
                admin_box.checked = true;
            }
            element.appendChild(admin_description);
            element.appendChild(admin_box);
            element.appendChild(document.createElement('br'));

            edit_button = document.createElement('button');
            edit_button.appendChild(document.createTextNode('Edit Data'));
            element.appendChild(edit_button);
            edit_button.addEventListener("click", function(){edit(item.id);});
            
            password_button = document.createElement('button');
            password_button.appendChild(document.createTextNode('Change Password'));
            password_button.addEventListener("click", function(){change_password(item.id);});
            element.appendChild(password_button);

            delete_button = document.createElement('button');
            delete_button.appendChild(document.createTextNode('Delete'));
            delete_button.addEventListener("click", function(){delete_user(item.id);});
            element.appendChild(delete_button);

            list.appendChild(element);
        });
    }, function(res, status){
        if(status == 403){
            window.location.replace('login.html');
        }else{
            notify("Error when loading: " + String(res));
        }
    });
}

function create_user(){
    username_field = document.getElementById("username");
    email_field = document.getElementById("email");
    given_names_field = document.getElementById("given_names");
    family_name_field = document.getElementById("family_name");
    admin_field = document.getElementById("admin");
    password_field = document.getElementById("password");
    confirm_field = document.getElementById("confirm");


    if(password_field.value !== confirm_field.value){
        notify("Passwords do not match");
    }else{
        body = {
            'username': username_field.value,
            'email': email_field.value,
            'given_names': given_names_field.value,
            'family_name': family_name.value,
            'admin': admin_field.checked,
            'password': password_field.value
        }
        apiCall(PATH_USER, POST, body, function(res){
            notify("Created user");
            load();
        }, function(res, status){
            if(status == 403){
                window.location.replace("login.html");
            }else{
                notify("Error creating user: " + String(res));
            }
        });
    }
}

function delete_user(id){
    apiCall(PATH_USER+"/"+String(id), DELETE, null, function(res){
        notify("Deleted user");
        load();
    }, function(res, status){
        if(status===403){
            window.location.replace("login.html");
        }else{
            notify("Error deleting user: " + String(res))
        }
    });
}

document.addEventListener("DOMContentLoaded", function(event) {
    username_field = document.getElementById("username");
    email_field = document.getElementById("email");
    given_names_field = document.getElementById("given_names");
    family_name_field = document.getElementById("family_name");
    password_field = document.getElementById("password");
    confirm_field = document.getElementById("confirm");

    onEnter(username_field, create_user);
    onEnter(email_field, create_user);
    onEnter(given_names_field, create_user);
    onEnter(family_name_field, create_user);
    onEnter(password_field, create_user);
    onEnter(confirm_field, create_user);

    document.getElementById("create_user").addEventListener("click", create_user);

    load();
});

