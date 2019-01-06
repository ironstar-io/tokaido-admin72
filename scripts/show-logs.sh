#!/usr/bin/env bash
multitail --follow-all -ci green -I /tokaido/logs/nginx/access.log -ci red -I /tokaido/logs/nginx/error.log -ci blue -I /tokaido/logs/varnish/varnish.log