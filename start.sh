bundle exec thin stop 2> /dev/null
sleep 1
bundle exec thin -R config.ru -d start
