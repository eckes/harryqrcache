# Timed Geocaching Game

This small web app is used for a geocaching game that uses smartphones

## Basic Idea

The idea is to put some time pressure into geocaching.

One scans a QR code on the beginning of the cache and receives a token along with the coordinates for the next target.

As soon as the token is issued, time begins to run.

There could be various stations between the first and the next-to-last.

The challenge is to receive this next-to-last checkpoint within a defined time window. Only if you arrive within this time window, you'll receive the coordinates for the last checkpoint. If you're too soon, you'll have to wait; if you're too late, you won't get the coordinates for the last point.

## Tech stuff

The parameters of the app could be modified via the management interface available at '/private/settings'. 

Authentication is done by means of OpenID via Google. 

Settings are store in a PostgreSQL database or in environment variables.

## Live

This app runs on heroku: http://tranquil-gorge-3863.herokuapp.com

## Ressources

- [QR Code Generator](http://goqr.me/#t=url)
- [Heroku](http://www.heroku.com)
