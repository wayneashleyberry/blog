#!/bin/sh
rm -rf public
./node_modules/.bin/tailwindcss -i ./src/input.css -o ./assets/css/style.min.css --minify
hugo --minify
firebase deploy
