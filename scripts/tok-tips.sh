#!/usr/bin/env bash

arr[0]="Tip: Run 'show-logs' inside this container to view \na combined log output for Varnish, Nginx, and FPM"
arr[1]="Tip: You can configure most PHP variables in Tokaido. \nCheck out https://docs.tokaido.io for more info"
arr[2]="Tip: Drush aliases work in Tokaido! \nJust place them in the /tokaido/site/drush/sites folder"


rand=$[ $RANDOM % 3 ]
echo -e ${arr[$rand]}