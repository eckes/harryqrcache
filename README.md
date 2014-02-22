# Timed Geocaching Game

This small web app is used for a geocaching game that uses smartphones

## Basic Idea

The idea is to put some time pressure into geocaching.

One scans a QR code on the beginning of the cache and receives a token along with the coordinates for the next target.

As soon as the token is issued, time begins to run.

There could be various stations between the first and the next-to-last.

The challenge is to receive this next-to-last checkpoint within a defined time window. 
If one arrives on time, there shall be another QR code which calls the check page. If the token is yet and still valid, the coordinates for the last checkpoint are shown.
If you're too soon, you'll have to wait; if you're too late, you won't get the coordinates for the last point.

## Live

This app runs on heroku: http://tranquil-gorge-3863.herokuapp.com

To start the timer (on the live app), scan this QR code:

![StartCache QR Code](https://api.qrserver.com/v1/create-qr-code/?data=http%3A%2F%2Ftranquil-gorge-3863.herokuapp.com%2Fstartcache&size=220x220&margin=0)

To see the result, scan this one:

![EndCache QR Code](https://api.qrserver.com/v1/create-qr-code/?data=http%3A%2F%2Ftranquil-gorge-3863.herokuapp.com%2Fendcache&size=220x220&margin=0)

## Tech stuff

The app is written in [Ruby](https://www.ruby-lang.org), [Slim](http://slim-lang.com) is used as template framework.

The parameters of the app could be modified via the management interface available at '/private/settings'. 

Authentication is done by means of OpenID via Google. 

Settings are store in a PostgreSQL database or in environment variables.

## Ressources

- [QR Code Generator](http://goqr.me/#t=url)
- [Heroku](http://www.heroku.com)
