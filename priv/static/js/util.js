const GET = "GET"
const POST = "POST"
const PUT = "PUT"
const DELETE = "DELETE"

function apiCall(path, method, body, onSuccess, onError=console.warn) {
    function transferComplete() {
        try {
            if (this.getResponseHeader('content-type').includes("application/json")) {
                var res = JSON.parse(this.responseText);
            } else {
                var res = this.responseText;
            }
            if (this.status > 399) {
                onError(res, this.status);
            } else {
                onSuccess(res);
            }
        } catch (e) {
            console.warn(e);
            onError(e, 600)
        }
    }

    function transferFailed(e) {
        console.warn("Transfer Failed: ", e);
        onError(e, 600)
    }

    var xhr = new XMLHttpRequest();
    xhr.addEventListener("load", transferComplete);
    xhr.addEventListener("error", transferFailed);

    xhr.open(method, path);

    if (body == null) {
        xhr.send();
    } else {
        xhr.setRequestHeader('content-type', 'application/json');
        xhr.send(JSON.stringify(body))
    }
}

function removeAllChildNodes(parent){
    while(parent.firstChild) {
        parent.removeChild(parent.firstChild);
    }
}

function onEnter(field, fun){
    field.addEventListener("keydown", function(e){
        if(e.code === "Enter"){
            fun(e);
        }
    });
}

function getParams(){
    return new Proxy(new URLSearchParams(window.location.search), {
        get: (searchParams, prop) => searchParams.get(prop),
    });
}

