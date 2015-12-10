#!/user/bin/env sh

cp Personalization.dict Personalization
vagrant up --provider=virtualbox
sleep 60
vagrant halt

