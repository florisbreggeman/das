const PATH_LOGIN = "session/login";
const PATH_TOTP = "session/totp_login";

function notify(message) {
    let el = document.getElementById("notifications");
    el.innerText = message
}

function send_totp() {
    let code = document.getElementById('totp_code').value;
    body = {
        'code': code
    }
    apiCall(PATH_TOTP, POST, body, function(res){
        const params = getParams();
        const redirect = params.redirect;
        if(redirect === null){
            window.location.replace("index.html");
        }else{
            window.location.replace(redirect);
        }
    }, function(res, status){
        if(status === 403){
            notify("Incorrect two-factor authentication code");
        }else{
            notify("Unknown error (code " + String(status) + "): " + res)
        }
    });
}
    

function submit() {
    username_field = document.getElementById("username");
    password_field = document.getElementById("password");

    body = {
        "username": username_field.value,
        "password": password_field.value
    }

    //first define the functions for error and success of the API call
    function onError(res, status) {
        if(status === 403){
            notify(res);
        }else{
            notify("Unknown error (code " + String(status) + "): " + res);
        }
    }
    function onSuccess(res, status) {
        if(status === 202){
            //this means we'll have to do TOTP
            //first, remove the old form
            let title = document.getElementById('title')
            removeAllChildNodes(title);
            title.appendChild(document.createTextNode("Please enter your two-factor authentication code"));
            let notifications = document.getElementById('notifications');
            if(notifications !== null){
                notifications.innerText = "";
            }
            let form_p = document.getElementById('form');
            removeAllChildNodes(form_p);
            let code_label = document.createElement('label');
            code_label.for = 'totp_code';
            code_label.appendChild(document.createTextNode('Two-factor authentication code'));
            form_p.appendChild(code_label);
            let code_field = document.createElement('input');
            code_field.id = 'totp_code';
            code_field.placeholder = 'two-factor authentication code';
            code_field.type='number';
            code_field.classList.add('pure-input-1');
            code_field.min = 0;
            code_field.max = 999999;
            onEnter(code_field, send_totp);
            form_p.appendChild(code_field);

            let submit = document.createElement('button');
            submit.id = 'submit';
            submit.appendChild(document.createTextNode('submit'));
            submit.addEventListener('click', send_totp);
            submit.classList.add('pure-button');
            submit.classList.add('pure-button-primary');
            form_p.append(submit);
        }else{
            const params = getParams();
            const redirect = params.redirect;
            if(redirect === null){
                window.location.replace('index.html');
            }else{
                window.location.replace('redirect');
            }
        }
    }

    function transferComplete() {
        try {
            let res = this.responseText;
            if (this.status > 399){
                onError(res, this.status);
            }else
                onSuccess(res, this.status);
        }catch(e){
            console.warn(e);
            onError(e, 600);
        }
    }
    //We actually need to load the status code on success for this function;
    //If the status code is 202, this means that we need to do TOTP.
    //Our standard apiCall function doesn't support this, so we'll quickly reimplement it.
    function transferFailed(e) {
        console.warn("Transfer failed: ", e);
        enError(e, 600);
    }

    let xhr = new XMLHttpRequest();
    xhr.addEventListener("load", transferComplete);
    xhr.addEventListener("error", transferFailed);
    xhr.open(POST, PATH_LOGIN);
    xhr.setRequestHeader('content-type', 'application/json');
    xhr.send(JSON.stringify(body));

}

document.addEventListener("DOMContentLoaded", function(event) {
    username_field = document.getElementById("username");
    password_field = document.getElementById("password");
    submit_field = document.getElementById("submit");

    onEnter(username_field, submit);
    onEnter(password_field, submit);
    submit_field.addEventListener("click", submit);
});

