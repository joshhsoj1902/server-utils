#!/bin/bash

docker image prune --all --filter "until=24h" --force