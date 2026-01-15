from flask import Flask, redirect, request
from requests_oauthlib import OAuth1Session
import os
import logging
from dotenv import load_dotenv


load_dotenv()

# ----- Flask Setup -----
app = Flask(__name__)
logging.basicConfig(level=logging.INFO)


# Garmin app 
CONSUMER_KEY = os.getenv("GARMIN_CONSUMER_KEY")
CONSUMER_SECRET = os.getenv("GARMIN_CONSUMER_SECRET")
GARMIN_CALLBACK_URL = os.getenv("GARMIN_CALLBACK_URL")

#  DICTIONARY needed to store users (not implemented it)
request_tokens = {} 
user_tokens = {}    

# OAuth flow 
@app.route("/garmin/oauth")
def start_oauth():
    oauth = OAuth1Session(
        client_key=CONSUMER_KEY,
        client_secret=CONSUMER_SECRET,
        callback_uri=GARMIN_CALLBACK_URL
    )
    fetch_response = oauth.fetch_request_token(
        "https://connectapi.garmin.com/oauth-service/oauth/request_token"
    )

    oauth_token = fetch_response.get('oauth_token')
    oauth_token_secret = fetch_response.get('oauth_token_secret')

    # Store secret temporarily
    request_tokens[oauth_token] = oauth_token_secret

    # Redirect user to Garmin authorization page
    auth_url = f"https://connect.garmin.com/oauthConfirm?oauth_token={oauth_token}"
    return redirect(auth_url)

# Oauth callback --> allows the server to have a token to access Garmin API for user
@app.route("/callback", methods=["GET"])
def oauth_callback():
    oauth_token = request.args.get("oauth_token")
    oauth_verifier = request.args.get("oauth_verifier")

    oauth_token_secret = request_tokens.get(oauth_token)
    if not oauth_token_secret:
        return "Request token not found. Start OAuth flow again.", 400

    oauth = OAuth1Session(
        client_key=CONSUMER_KEY,
        client_secret=CONSUMER_SECRET,
        resource_owner_key=oauth_token,
        resource_owner_secret=oauth_token_secret,
        verifier=oauth_verifier
    )

    # Fetch user-specific access token
    access_token = oauth.fetch_access_token(
        "https://connectapi.garmin.com/oauth-service/oauth/access_token"
    )

    # store the user to access token (HARDCODED WILL CHANGE)
    user_tokens['user'] = access_token

    logging.info(f"Access token obtained: {access_token}")
    return "OAuth completed! You are now authorized."


# THIS is the POST so showing data for the user. Currently I have activities set up
@app.route("/webhook", methods=["POST"])
def webhook():
    # TODO token storage- server restarts, token is gone, and therefore, no acces to user
    # need to have an endpoint for frontend to call (so maybe activities)
    data = request.json
    logging.info(f"Webhook received: {data}")
    return "", 200

# Run app
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5050, debug=True)
