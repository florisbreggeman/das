const PATH_LOGIN = "session/login"

function notify(message) {
    el = document.getElementById("notifications");
    el.innerText = message
}

function submit() {
    username_field = document.getElementById("username");
    password_field = document.getElementById("password");

    console.log(password_field)
 
    body = {
        "username": username_field.value,
        "password": password_field.value
    }

    apiCall(PATH_LOGIN, POST, body, function(_res) {
        const params = getParams();
        const redirect = params.redirect
        if(redirect === null){
            window.location.replace("index.html")
        }else{
            window.location.replace(redirect)
        }
    }, function(res, status) {
        if(status === 403){
            notify(res)
        }else{
            notify("Unknown error (code " + String(status) + "): " + res)
        }
    })
}

document.addEventListener("DOMContentLoaded", function(event) {
    username_field = document.getElementById("username");
    password_field = document.getElementById("password");
    submit_field = document.getElementById("submit");

    onEnter(username_field, submit);
    onEnter(password_field, submit);
    submit_field.addEventListener("click", submit);
});

