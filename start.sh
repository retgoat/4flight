#!/bin/bash

gem install bundler --no-rdoc --no-ri

bundle install

bundle exec shotgun -p 3000