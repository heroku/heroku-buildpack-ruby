#!/bin/sh

bundle exec rake rails:update:bin
bundle package --all