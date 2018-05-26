# ottobot

ottobot is a Mattermost bot.

## Installation

ottobot is a dart command-line application and requires only the [dart-vm](https://www.dartlang.org/dart-vm).

```shell
git clone [this repository]
cd ottobot
pub get
dart ottobot.dart
```

## Usage
The bot needs to be kept running in a background process so it can monitor Mattermost for trigger messages.

Currently the best way to achieve this is to simply call it from a crontab startup job:

```shell
@reboot dart /[path_to_script]/ottobot.dart
```
