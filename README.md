```sh
rm -rf public
hugo
./node_modules/.bin/tailwindcss -i ./src/input.css -o ./assets/css/style.min.css --minify
hugo --minify
firebase deploy
```
