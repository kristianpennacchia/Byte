<p align="center">
<img src="https://github.com/kristianpennacchia/Byte/assets/767677/546c79ba-25c4-4259-9eb2-c5b22a6a5f75" />
</p>

# Byte
An unofficial Twitch and YouTube app for tvOS built with SwiftUI.

### ⭐️ Highlights
- Watch live streams and VODs from both Twitch and YouTube.
- Watch Twitch at 1440p (2K).
- Seamlessly lists together your follows/subscriptions from both video streaming services.
- Multistream support - Watch as many streams simultaneously as you want so you don't miss anybody's POV!
- Spoiler filtering - Hide the thumbnails of games you haven't yet finished to avoid seeing spoilers (Twitch only).

### 🕹 Controls and Tips
- On the stream listing screen, press the ⏯ button on your Apple TV remote to select multiple streams at once, no limit. Press the clickpad to start watching them all.
- On the stream or game listing screens, long press the clickpad to bring up the spoiler filter (Twitch only).
- While watching a stream, press the clickpad to bring up some options.
- While watching a stream, long press the clickpad to refresh the stream (useful if the stream buffered and is behind live).

<p align="center">
<img src="https://github.com/user-attachments/assets/d8ef1692-5705-4b44-88bd-540ae3521745" width=30% height=30%> <img src="https://github.com/user-attachments/assets/b896e4b1-a008-449d-a11f-e0a60fc7d620" width=30% height=30%> <img src="https://github.com/user-attachments/assets/6f74258d-6bfe-493d-9463-eb89aeb967da" width=30% height=30%>
</p>

### 🛠 Project setup
This project must be built from source, I do not currently provide a compiled app.

In order for this project to run and work, it requires you to create a `Secrets.json` file in the 'Shared' directory. This JSON file holds all of the sensitive keys required to enable user authorization within the app, get followed channels and watch streams. You will have to provide all of this information yourself. The contents of the JSON file should look as follows:

##### Minimal JSON

```json
{
	"twitch": {
		"clientID": {
			"twitch": "KEY_HERE",
			"byte": "KEY_HERE"
		},
		"secret": {
			"byte": "KEY_HERE"
		}
	}
}
```

#### Full JSON

```json
{
	"(OPTIONAL) twitch": {
		"(OPTIONAL) previewUsername": "TWITCH_USERNAME_FOR_SWIFTUI_PREVIEWS",
		"clientID": {
			"twitch": "KEY_HERE",
			"byte": "KEY_HERE"
		},
		"secret": {
			"byte": "KEY_HERE"
		},
		"(OPTIONAL) oAuthToken": {
			"(OPTIONAL) webUserAccessToken": "KEY_HERE",
			"byteUserAccessToken": "KEY_HERE",
			"byteUserRefreshToken": "KEY_HERE"
		}
	},
	"(OPTIONAL) youtube": {
		"clientID": {
			"byte": "KEY_HERE"
		},
		"secret": {
			"byte": "KEY_HERE"
		}
	}
}
```

Providing `oAuthToken` for Twitch allows you to skip manual sign-in. If you do not provide one, you will instead be able to sign in using the OAuth flow within the app.

Both Twitch and YouTube support is **optional**. If you do not want to support YouTube, change the JSON to look like this:

```
"twitch": null,
"youtube": null
```

Obviously, excluding support for both means the app will be useless.

### How To Get The Above Information

**Twitch Client ID**

This comes from the Twitch network response data and does not change. It is `kimne78kx3ncx6brgo4mv6wki5h1ko`.

**Your App (Byte) Client ID and Secret**

_Required for Twitch support_

1. Go to https://dev.twitch.tv.
2. Log in with your Twitch account.
3. Go to 'Console'.
4. Go to 'Applications'.
5. Select 'Register Your Application'.
6. Name it whatever you want, mine is "Byte" obviously.
7. The redirect URL should be `https://twitchtokengenerator.com`.
8. The category can be anything. I use 'Browser Extension'.
9. Once you have finished registering your app, the **Client ID** and **Secret** should be displayed to you.

**(OPTIONAL) Your Twitch account OAuth token for your registered application (Byte)**

1. Login to https://twitch.tv.
2. Go to https://twitchtokengenerator.com.
3. Paste in your Client Secret and Client ID from the previous step.
4. Enable the `user:read:follows` permission.
5. Click the green 'Generate Token!' button.
6. Follow the prompts.
7. Once you have been redirected back to https://twitchtokengenerator.com find the newly generated "ACCESS TOKEN" and "REFRESH TOKEN" and copy them. These are your OAuth tokens.

The `webUserAccessToken` is optional, but will allow you to:
- Skip ads if you are a subscriber to the channel.
- Watch higher quality streams that Twitch requires you to login to view e.g. 1440p.
- Receive Twitch drops.

You can get this token by logging into the Twitch website in your web browser on a Mac/PC and get the `auth-token` from your cookies. For more info, see: https://github.com/streamlink/streamlink/blob/master/docs/cli/plugins/twitch.rst#authentication

**YouTube**

_Required for YouTube support_

This app uses the YouTube Data API, so you will need to create an account (free) and follow the following guide to generate the necessary Client ID and Client Secret tokens.

Guide: https://developers.google.com/youtube/v3/guides/auth/devices

When prompted for a project name or project ID/bundle ID, just enter whatever you want.
