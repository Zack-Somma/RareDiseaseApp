from flask import Flask, redirect, request, jsonify
from requests_oauthlib import OAuth1Session
import os
import logging
import time
from datetime import datetime, timedelta
import statistics
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


@app.route("/hrv", methods=["GET"])
def get_hrv():
    """Proxy HRV data from Garmin Health API. Requires OAuth to be completed."""
    tokens = user_tokens.get("user")
    if not tokens:
        return "User not authorized. Complete /garmin/oauth first.", 400
    resource_owner_key = tokens.get("oauth_token")
    resource_owner_secret = tokens.get("oauth_token_secret")
    if not resource_owner_key or not resource_owner_secret:
        return "Invalid stored tokens.", 500
    oauth = OAuth1Session(
        client_key=CONSUMER_KEY,
        client_secret=CONSUMER_SECRET,
        resource_owner_key=resource_owner_key,
        resource_owner_secret=resource_owner_secret,
    )
    start_param = request.args.get("uploadStartTimeInSeconds")
    end_param = request.args.get("uploadEndTimeInSeconds")
    if not start_param or not end_param:
        now = int(time.time())
        day_ago = now - 24 * 60 * 60
        start_param, end_param = str(day_ago), str(now)
    params = {"uploadStartTimeInSeconds": start_param, "uploadEndTimeInSeconds": end_param}
    if request.args.get("token"):
        params["token"] = request.args.get("token")
    resp = oauth.get("https://apis.garmin.com/wellness-api/rest/hrv", params=params)
    if resp.status_code != 200:
        logging.error("HRV request failed: %s %s", resp.status_code, resp.text)
        return f"Error from Garmin Health API ({resp.status_code}): {resp.text}", resp.status_code
    try:
        return jsonify(resp.json())
    except ValueError:
        return "Failed to decode HRV JSON response.", 502


@app.route("/hrv/rolling21", methods=["GET"])
def get_hrv_rolling21():
    """
    Call Garmin Health API for HRV, then compute 21-day rolling average and 10th/90th percentile bounds.
    Returns baseline (average, percentile10, percentile90) only when there are at least 21 days of data.
    """
    tokens = user_tokens.get("user")
    if not tokens:
        return "User not authorized. Complete /garmin/oauth first.", 400
    resource_owner_key = tokens.get("oauth_token")
    resource_owner_secret = tokens.get("oauth_token_secret")
    if not resource_owner_key or not resource_owner_secret:
        return "Invalid stored tokens.", 500
    oauth = OAuth1Session(
        client_key=CONSUMER_KEY,
        client_secret=CONSUMER_SECRET,
        resource_owner_key=resource_owner_key,
        resource_owner_secret=resource_owner_secret,
    )
    now = int(time.time())
    three_weeks_ago = now - (21 * 24 * 60 * 60)
    params = {
        "uploadStartTimeInSeconds": str(three_weeks_ago),
        "uploadEndTimeInSeconds": str(now),
    }
    resp = oauth.get("https://apis.garmin.com/wellness-api/rest/hrv", params=params)
    if resp.status_code != 200:
        logging.error("HRV request failed: %s %s", resp.status_code, resp.text)
        return f"Error from Garmin Health API ({resp.status_code}): {resp.text}", resp.status_code
    try:
        hrv_summaries = resp.json()
    except ValueError:
        return "Failed to decode HRV JSON response.", 502
    if not hrv_summaries or not isinstance(hrv_summaries, list):
        return jsonify({
            "error": "No HRV data available",
            "average": None,
            "percentile10": None,
            "percentile90": None,
            "daysIncluded": 0,
            "dateRange": None,
        })
    daily_values = {}
    for summary in hrv_summaries:
        date_str = summary.get("calendarDate")
        avg_value = summary.get("lastNightAvg")
        if date_str and avg_value is not None:
            try:
                date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
                daily_values[date_obj] = avg_value
            except (ValueError, TypeError):
                continue
    if not daily_values:
        return jsonify({
            "error": "No valid HRV data found",
            "average": None,
            "percentile10": None,
            "percentile90": None,
            "daysIncluded": 0,
            "dateRange": None,
        })
    most_recent_date = max(daily_values.keys())
    window_start = most_recent_date - timedelta(days=20)
    window_values = [v for d, v in daily_values.items() if window_start <= d <= most_recent_date]
    if not window_values:
        return jsonify({
            "error": "No data in 21-day window",
            "average": None,
            "percentile10": None,
            "percentile90": None,
            "daysIncluded": 0,
            "dateRange": {"start": window_start.isoformat(), "end": most_recent_date.isoformat()},
        })
    days_included = len(window_values)
    date_range = {"start": window_start.isoformat(), "end": most_recent_date.isoformat()}
    if days_included < 21:
        return jsonify({
            "error": "Need 21 days of HRV data for baseline",
            "average": None,
            "percentile10": None,
            "percentile90": None,
            "daysIncluded": days_included,
            "dateRange": date_range,
        })
    average = statistics.mean(window_values)
    percentile10 = statistics.quantiles(window_values, n=10)[0]
    percentile90 = statistics.quantiles(window_values, n=10)[8]
    return jsonify({
        "average": round(average, 2),
        "percentile10": round(percentile10, 2),
        "percentile90": round(percentile90, 2),
        "daysIncluded": days_included,
        "dateRange": date_range,
    })


# Run app
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5050, debug=True)
