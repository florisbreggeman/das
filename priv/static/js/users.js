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
    given_names_field = element.querySelector('.given_names');
    family_name_field = element.querySelector('.family_name');
    admin_field = element.querySelector('.admin');

    body = {
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

            email_description = document.createElement('b');
            email_description.appendChild(document.createTextNode('Email: '));
            element.appendChild(email_description);
            email_field = document.createElement('span');
            email_field.appendChild(document.createTextNode(item.email));
            element.appendChild(email_field);
            element.appendChild(document.createElement('br'));

            given_names_field = add_field("Given Names:", 'given_names', item.given_names, element);
            onEnter(given_names_field, function(){
                edit(item.id)
            });
            family_name_field = add_field("Family Name:", 'family_name', item.family_name, element);
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

document.addEventListener("DOMContentLoaded", function(event) {
    load();
});

