const PATH_WHOAMI = 'session/whoami';
const PATH_CHANGE_PASSWORD = 'session/change_password';
const PATH_LOGOUT = "session/logout";

function add_text_field(description, text, box){
    let description_element = document.createElement('b');
    description_element.appendChild(document.createTextNode(description));
    let element = document.createElement('span');
    element.appendChild(document.createTextNode(text));

    box.appendChild(description_element);
    box.appendChild(element);
    box.appendChild(document.createElement('br'));
}

function load_me(){
    apiCall(PATH_WHOAMI, GET, null, function(res){
        let box = document.getElementById('whoami');
        removeAllChildNodes(box);
        add_text_field("Username: ", res.username, box);
        add_text_field("Email: ", res.email, box);
        add_text_field("Given names: ", res.given_names, box);
        add_text_field("Family name: ", res.family_name, box);
        
        if(res.admin){
            let element = document.createElement('span');
            element.appendChild(document.createTextNode('You are an administrator'));
            box.appendChild(element);
        }

        given_names_field = document.getElementById('given_names_field');
        given_names_field.value = res.given_names;
        family_name_field = document.getElementById('family_name_field');
        family_name_field.value = res.family_name;
    }, function(res, status) {
        if(status == 403){
            window.location.replace("login.html")
        }
    });
}

function submit_form(){
    given_names_field = document.getElementById('given_names_field');
    family_name_field = document.getElementById('family_name_field');
    body = {
        'given_names': given_names_field.value,
        'family_name': family_name_field.value
    }
    apiCall(PATH_WHOAMI, PUT, body, function(res){
        load_me();
    }, function(res, status) {
        if(status == 403){
            window.location.replace("login.html")
        }
    });
}

function change_password(){
    password_field = document.getElementById('password');
    confirm_field = document.getElementById('password_confirm');
    old_field = document.getElementById('old_password');

    if(password_field.value === "" || confirm_field.value === "" || old_field.value === ""){
        return;
    }

    notify = document.getElementById('password_notify');

    if(password_field.value !== confirm_field.value){
        removeAllChildNodes(notify);
        notify.appendChild(document.createTextNode('Passwords do not match'));
    }else{
        body = {
            'current_password': old_field.value,
            'new_password': password_field.value
        }
        apiCall(PATH_CHANGE_PASSWORD, PUT, body, function(res){
            removeAllChildNodes(notify);
            notify.appendChild(document.createTextNode("Password changed"));
        }, function(res, status){
            removeAllChildNodes(notify);
            if(status == 500){
                notify.appendChild(document.createTextNode('Unknown error'));
            }else{
                notify.appendChild(document.createTextNode(String(res)));
            }
        });
    }
}

function logout(){
    apiCall(PATH_LOGOUT, POST, null, function(res){
        window.location.replace("login.html");
    }, function(status, res){
        if(status == 403){
            window.location.replace("login.html");
        }else{
            alert("Unknown error logging out: " + String(res))
        }
    });
}

document.addEventListener("DOMContentLoaded", function(event) {
    load_me();

    given_names_field = document.getElementById("given_names_field");
    family_name_field = document.getElementById("family_name_field");
    submit_button = document.getElementById("submit");

    onEnter(given_names_field, submit_form);
    onEnter(family_name_field, submit_form);
    submit_button.addEventListener("click", submit_form);

    password_field = document.getElementById('password');
    confirm_field = document.getElementById('password_confirm');
    old_field = document.getElementById('old_password');
    change_button = document.getElementById('change_password');

    onEnter(password_field, change_password);
    onEnter(confirm_field, change_password);
    onEnter(old_field, change_password);
    change_button.addEventListener("click", change_password);

    logout_button = document.getElementById('logout');
    logout_button.addEventListener("click", logout);
});
        
