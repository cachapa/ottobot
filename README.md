# Lunchbot

Lunchbot is a Mattermost bot that fetches, parses and posts the lunch menus from a number of restaurants.

## Installation

Lunchbot is a dart command-line application and requires only the [dart-vm](https://www.dartlang.org/dart-vm).

```shell
git clone [this repository]
cd lunchbot
pub get
dart lunchbot.dart
```

## Usage
The bot needs to be kept running in a background process so it can monitor the channel for trigger messages.

Currently the best way to achieve this is to simply call it from a crontab startup job:

```shell
@reboot dart /[path_to_script]/lunchbot.dart
```

