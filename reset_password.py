import sys
import requests_unixsocket
import urllib.parse

args = sys.argv
if args[0] == "python3" or args[0] == "python":
    args = sys.argv[1:]

socket = "/tmp/das_util.sock"
if len(args) > 1:
    socket = args[1]

session = requests_unixsocket.Session()

url_socket = urllib.parse.quote(socket, safe='')
r = session.get("http+unix://"+url_socket+"/user/")

print("Which user would you like to change the password for?")
users = r.json()
for user in users:
    print(user["id"], user["name"])

userid = input("Please enter the user ID: ")

r = session.put("http+unix://"+url_socket+"/user/"+userid+"/change_password")
if r.status_code == 200:
    print("The password has been successfully changed! The new password is:")
    res = r.json()
    print(res["password"])
else:
    print("Failed changing the password with status code", r.status_code, ". Response body:")
    print(r.text)

