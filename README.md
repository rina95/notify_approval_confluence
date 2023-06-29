# README

### Development Environment
- Ruby version: 3.1.2
- Rails version: 7.0.4

### Set up
1. run: 
```
docker-compose build
docker-compose up -d
docker-compose run --rm web bundle exec rails db:create db:migrate

```
