#catchmybus

A simple little app that lives in the Mac's menubar and displays when the next bus or tram leaves the stop you specify (in Dresden, Germany).
You can also choose a specific bus or tram to be notified about when it's getting close.

The selection of custom stops is unfortunately not possible quite yet. It's coming :blush:

Runs on OS X 10.9 Mavericks and 10.10 Yosemite.

## Download

Check the [releases](https://github.com/kiliankoe/catchmybus/releases) page for downloading the most current version.

## Screenshots

![screenshot](./screenshot1.png)
![screenshot](./screenshot2.png)

## Compiling

You'll need a Mac running OS X 10.10 Yosemite as it's unfortunately not possible to build Swift apps on anything below. You'll still be able to run the app on Mavericks though. Check the [releases](https://github.com/kiliankoe/catchmybus/releases) page.

Be sure to also check out [Alamofire](https://github.com/alamofire/alamofire) (or clone it to the project directory manually) as this fantastic framework is used for the HTTP requests.

#### Troubleshooting

```
Clone of 'git@github.com:Alamofire/Alamofire.git' into submodule path 'Alamofire' failed
```
If you see an error the likes of this, please either use SSH authentication for GitHub or just clone the Alamofire repository in the project directory manually.

After cloning Xcode will also ask you for your developer account when trying to compile. This is due to the fact that Alamofire's default deployment target is set to iOS, not OS X. This is a single setting shown in the following screenshot.

![screenshot](http://i.imgur.com/ZQJWsww.png)

## Credits

Name and idea shamelessly stolen from [hoodie/catch-my-bus](https://github.com/hoodie/catch-my-bus).
