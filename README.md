# Byte
An unofficial Twitch app for tvOS built with SwiftUI.

### 🛠 Project setup
In order for this project to run and work, it requires you to create a `Secrets.json` file in the 'Shared' directory. This JSON file holds all of the sensitive keys used to login, get followed channels and watch streams. You will have to provide all of this information yourself. The contents of the JSON file should look as follows:

```json
{
    "twitch": {
        "previewUsername": "TWITCH_USERNAME_FOR_SWIFTUI_PREVIEWS",
        "clientID": {
            "twitch": "KEY_HERE",
            "byte": "KEY_HERE",
        },
        "secret": {
            "byte": "KEY_HERE",
        },
        "oAuthToken": {
            "byteUserAccessToken": "KEY_HERE",
            "byteUserRefreshToken": "KEY_HERE",
        },
    },
    "youtube": {
        "clientID": {
            "byte": "KEY_HERE",
        },
        "secret": {
            "byte": "KEY_HERE",
        },
    },
}

```

Youtube support is **optional**. If you do not want to support Youtube, change the JSON to look like this:

```
"youtube": null,
```

### How To Get The Above Information

**Twitch Client ID**

This comes from the Twitch network response data and does not change. It is `kimne78kx3ncx6brgo4mv6wki5h1ko`.

**Your App (Byte) Client ID and Secret**

1. Go to https://dev.twitch.tv.
2. Log in with your Twitch account.
3. Go to 'Console'.
4. Go to 'Applications'.
5. Select 'Register Your Application'.
6. Name it whatever you want, mine is "Byte" obviously.
7. The redirect URL should be `https://twitchtokengenerator.com`.
8. The category can be anything. I use 'Browser Extension'.
9. Once you have finished registering your app, the **Client ID** and **Secret** should be displayed to you.

**Your Twitch account OAuth token for your registered application (Byte)**

1. Login to https://twitch.tv.
2. Go to https://twitchtokengenerator.com.
3. Paste in your Client Secret and Client ID from the previous step.
4. Enable the `user:read:follows` permission.
5. Click the green 'Generate Token!' button.
6. Follow the prompts.
7. Once you have been redirected back to https://twitchtokengenerator.com find the newly generated "ACCESS TOKEN" and "REFRESH TOKEN" and copy them. These are your OAuth tokens.

**Youtube**

This app uses the Youtube Data API, so you will need to create an account (free) and follow the following guide to generate the necessary Client ID and Client Secret tokens.
 
Guide: https://developers.google.com/youtube/v3/guides/auth/devices
 
When prompted for a project name or project ID/bundle ID, just enter whatever you want.
