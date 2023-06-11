const PATH_WHOAMI = 'session/whoami';
const PATH_CHANGE_PASSWORD = 'session/change_password';
const PATH_LOGOUT = "session/logout";
const PATH_TOTP = "session/totp";

function failure(res, status){
    if(status == 403){
        window.location.replace("login.html?redirect=index.html")
    }
}

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
        let username_field = document.getElementById('username_field');
        username_field.value = res.username;
        let email_field = document.getElementById('email_field');
        email_field.value = res.email;
        let name_field = document.getElementById('name_field');
        name_field.value = res.name;
        
        if(res.admin){
            let admin_span = document.getElementById('admin_span');
            admin_span.style.display = 'inline';
            let logout_button = document.getElementById('logout');
            logout_button.style.display = 'none';
        }else{
            let menu = document.getElementById('menu');
            menu.style.display = 'none';
            let menu_link = document.getElementById('menuLink');
            menu_link.style.display = 'none';
        }


        let totp_checkbox = document.getElementById('totp_checkbox');
        if(res.totp_enabled){
            totp_checkbox.checked = true;
            add_totp_buttons(res.totp_ldap);
        }else{
            totp_checkbox.checked = false;
            let totp_button = document.getElementById('totp_button');
            if(totp_button !== null){
                totp_button.remove();
            }
            let totp_ldap = document.getElementById('totp_ldap');
            if(totp_ldap !== null){
                totp_ldap.remove();
            }
        }
    }, failure);
}

function submit_form(){
    name_field = document.getElementById('name_field');
    body = {
        'name': name_field.value
    }
    apiCall(PATH_WHOAMI, PUT, body, function(res){
        Jackbox.success('Changed Data');
    }, failure);
}

function change_password(){
    password_field = document.getElementById('password');
    confirm_field = document.getElementById('password_confirm');
    old_field = document.getElementById('old_password');

    if(password_field.value === "" || confirm_field.value === "" || old_field.value === ""){
        return;
    }

    if(password_field.value !== confirm_field.value){
        Jackbox.warning('Passwords do not match');
    }else{
        body = {
            'current_password': old_field.value,
            'new_password': password_field.value
        }
        apiCall(PATH_CHANGE_PASSWORD, PUT, body, function(res){
            Jackbox.success("Password changed");
        }, function(res, status){
            if(status == 500){
                Jackbox.error('Unknown error');
            }else{
                Jackbox.error(String(res));
            }
        });
    }
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

function view_totp_code(){
    apiCall(PATH_TOTP, GET, null, function(res){
        let el = document.getElementById('totp_qr_code');
        let button = document.getElementById('totp_button');
        if(el === null){
            el = document.createElement('div');
            el.id = 'totp_qr_code';
            let totp_p = document.getElementById('totp');
            totp_p.appendChild(el);
            el.innerHTML = res;
            button.innerText='Hide Secret QR Code';
        }else{
            el.remove();
            button.innerText = 'View Secret QR Code';
        }

    }, failure);
}

function update_totp_ldap(){
    let checkbox = document.getElementById('totp_ldap_checkbox');
    let body = {
        'totp_ldap': checkbox.checked
    }
    apiCall(PATH_WHOAMI, PUT, body, function(res){
        if(checkbox.checked){
            Jackbox.information("Enabled two-factor for LDAP");
        }else{
            Jackbox.information('Disabled two-factor for LDAP');
        }
    }, function(res, status){
        Jackbox.error("Uknown error (code " + String(status) + "): " + res);
    });
}

function add_totp_buttons(totp_ldap){
    let totp_p = document.getElementById('totp');
    if(document.getElementById('totp_ldap_span') === null){
        let totp_ldap_span = document.createElement('span');
        totp_ldap_span.id = 'totp_ldap';
        let label = document.createElement('label')
        label.for = 'totp_ldap_checkbox';
        label.appendChild(document.createTextNode('Enable two-factor authentication for LDAP '))
        totp_ldap_span.appendChild(label);
        let checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.checked = totp_ldap
        checkbox.id = 'totp_ldap_checkbox';
        checkbox.classList.add('pure-checkbox');
        checkbox.addEventListener('change', update_totp_ldap);
        totp_ldap_span.appendChild(checkbox);
        totp_ldap_span.appendChild(document.createElement('br'));
        let exp_span = document.createElement('span');
        exp_span.style.color = '#666';
        exp_span.style.fontSize = '0.95em';
        let explanation = document.createTextNode('If checked, you must append your two-factor authentication to your password when logging in to LDAP applications. If, for example, your password is "qwerty", and your code is "123 456", you must enter "qwerty123456" for LDAP applications.');
        exp_span.appendChild(explanation);
        totp_ldap_span.appendChild(exp_span);
        totp_ldap_span.appendChild(document.createElement('br'));
        totp_ldap_span.appendChild(document.createElement('br'));
        totp_p.appendChild(totp_ldap_span);
    }
    if(document.getElementById('totp_button') === null){
        let totp_button = document.createElement('button')
        totp_button.appendChild(document.createTextNode('View Secret QR Code'));
        totp_button.id = 'totp_button';
        totp_button.classList.add('pure-button');
        totp_button.addEventListener('click', view_totp_code);
        let br = document.createElement('br');
        br.id = 'totp_button_br';
        totp_p.appendChild(totp_button);
        totp_p.appendChild(br);
    }
    if(document.getElementById('totp_img') === null){
        let totp_img_div = document.createElement('div');
        totp_img_div.id = 'totp_img';
        totp_p.appendChild(totp_img_div);
    }


}

function update_totp() {
    let totp_checkbox = document.getElementById('totp_checkbox');
    if(totp_checkbox.checked){
        //enable TOTP
        apiCall(PATH_TOTP, POST, null, function(res){
            Jackbox.success("Two-factor authentication has been enabled");
            view_totp_code();
            add_totp_buttons(false);
        }, failure)
    }else{
        //disable TOTP
        apiCall(PATH_TOTP, DELETE, null, function(res){
            Jackbox.success("Two-factor authentication has been disabled");
            let totp_button = document.getElementById('totp_button');
            if(totp_button !== null){
                totp_button.remove();
                document.getElementById('totp_button_br').remove();
                document.getElementById('totp_ldap').remove();
            }
            let qr_code = document.getElementById('totp_qr_code');
            if(qr_code !== null){
                qr_code.remove();
            }
        }, failure)
    }
}

document.addEventListener("DOMContentLoaded", function(event) {
    Jackbox.init();
    load_me();

    let name_field = document.getElementById("name_field");
    let submit_button = document.getElementById("submit");

    onEnter(name_field, submit_form);
    submit_button.addEventListener("click", submit_form);

    let password_field = document.getElementById('password');
    let confirm_field = document.getElementById('password_confirm');
    let old_field = document.getElementById('old_password');
    let change_button = document.getElementById('change_password');

    onEnter(password_field, change_password);
    onEnter(confirm_field, change_password);
    onEnter(old_field, change_password);
    change_button.addEventListener("click", change_password);

    let logout_button = document.getElementById('logout');
    logout_button.addEventListener("click", logout);
    let logout_link = document.getElementById('logout-menu');
    logout_link.addEventListener("click", logout);

    let totp_checkbox = document.getElementById('totp_checkbox');
    totp_checkbox.addEventListener("change", update_totp);
});

//It's all Purecss from here on out
(function (window, document) {
    // we fetch the elements each time because docusaurus removes the previous
    // element references on page navigation
    function getElements() {
        return {
            layout: document.getElementById('layout'),
            menu: document.getElementById('menu'),
            menuLink: document.getElementById('menuLink')
        };
    }
    function toggleClass(element, className) {
        var classes = element.className.split(/\s+/);
        var length = classes.length;
        var i = 0;

        for (; i < length; i++) {
            if (classes[i] === className) {
                classes.splice(i, 1);
                break;
            }
        }
        // The className is not found
        if (length === classes.length) {
            classes.push(className);
        }

        element.className = classes.join(' ');
    }

    function toggleAll() {
        var active = 'active';
        var elements = getElements();

        toggleClass(elements.layout, active);
        toggleClass(elements.menu, active);
        toggleClass(elements.menuLink, active);
    }

    function handleEvent(e) {
        var elements = getElements();

        if (e.target.id === elements.menuLink.id) {
            toggleAll();
            e.preventDefault();
        } else if (elements.menu.className.indexOf('active') !== -1) {
            toggleAll();
        }
    }

    document.addEventListener('click', handleEvent);

}(this, this.document));
