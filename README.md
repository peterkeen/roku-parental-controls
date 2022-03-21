# Roku Parental Controls

Roku does not have parental controls.

What Roku _does_ have is an unauthenticated HTTP endpoint that allows you to, among other things, query the currently-running app and emulate remote key presses.

Eventually this will be a sophisticated system that will allow one to set up all manner of time-based rules:

* total minutes watched of a particular app per day
* app only allowed between the hours of X and Y
* etc?

Right now all `force_home.rb` does is watch for someone to launch an app and immediately press the `home` button.

![homer evil laugh](https://media.giphy.com/media/xT5LMD6ksHJYbKJCs8/giphy.gif)
