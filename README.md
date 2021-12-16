# Byte
An unofficial Twitch app for tvOS built with SwiftUI.

### 🛠 Project setup
In order for this project to run and work, it requires you to create a `Secrets.json` file in the 'Shared' directory. This JSON file holds all of the sensitive keys used to login, get followed channels and watch streams. You will have to provide all of this information yourself. The contents of the JSON file should look as follows:

```json
{
    "previewUsername": "TWITCH_USERNAME_FOR_SWIFTUI_PREVIEWS",
    "clientID": {
        "twitch": "KEY_HERE",
        "byte": "KEY_HERE",
        "streamLinkGUI": "KEY_HERE",
    },
    "secret": {
        "byte": "KEY_HERE",
    },
    "oAuthToken": {
        "byteUserMe": "KEY_HERE",
        "websiteUserMe": "KEY_HERE",
        "streamLinkGUIUserMe": "KEY_HERE",
    },
}
```
