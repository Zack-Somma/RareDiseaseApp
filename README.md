# RareDiseaseApp
A Garmin-based app to help individuals with hEDS track symptoms and convert those inputs, along with collected biometrics, into a simple health score. 

Setup for initial usage... run these commands in your terminal:
```
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
```
- After you run the commands, create a .env file and communicate with me (Claire) when you are here. 

How to use for the backend side:
1. Open terminal and run 'python3 app.py'
2. Open a new terminal (Terminal > New Terminal Window) and run ngrok http 5050
Need to authorize your user in order to check data by following these steps:
3. In a new browser copy and paste this link 
```
https://unabolished-superenergetic-nelle.ngrok-free.dev/garmin/oauth'
```
4. Sign in with your Garmin account, and agree with Garmin access. If everything works perfectly fine, you will receive a final print that says 'OAuth completed!'

Troubleshooting issues:
1. If you are getting a 403 Forbidden, run 
```curl -I http://localhost:5050/garmin/oauth```
and check the output

- If the output is 403 Forbidden, run:
```
pkill ngrok
pkill -f flask
```
and then restart the app

Current status for backend:
Backend created locally, have not done through a cloud based server
Real-time data can only be populated after the server is running, and able to collect the data back (worked with activities). Data demonstrated before wont be seen. 
So far need authorization is needed for every user each time