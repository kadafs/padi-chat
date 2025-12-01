#web: bundle exec rails server -p $PORT
#worker: bundle exec sidekiq -c 5 -v -q mailers,2 -q default
#bin/heroku-worker
worker: bundle exec sidekiq -C config/sidekiq.yml
web: bundle exec puma -C config/puma.rb

