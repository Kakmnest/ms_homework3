 Счётчик в Docker

Основной запуск с Redis:

cp .env.example .env
docker compose up --build --wait -d
curl <http://127.0.0.1:8080/>

 можно поменять `APP_PORT` и `GREETING`. Порт Redis наружу не опубликован. Redis пишет в `counter_data`.

Один контейнер

docker build -t ms-counter-demo .
docker run -d --name ms-counter-demo -p 127.0.0.1::8000 \
  -e 'GREETING=Привет от Docker' ms-counter-demo
address=$(docker port ms-counter-demo 8000/tcp)
curl --retry 10 --retry-all-errors --retry-delay 1 -fsS -w '\n' "http://$address/"
curl -fsS -w '\n' -X POST "http://$address/increment"
docker logs ms-counter-demo
docker rm -f ms-counter-demo

Первый запрос 0, POST 1. В логах оба 200.

SQLite через Compose

export APP_PORT=0 GREETING='Привет от Compose'
docker compose -f compose.sqlite.yaml up -d --build
address=$(docker compose -f compose.sqlite.yaml port app 8000)
curl --retry 10 --retry-all-errors --retry-delay 1 -fsS -w '\n' "http://$address/"
curl -fsS -w '\n' -X POST "http://$address/increment"
docker compose -f compose.sqlite.yaml down
docker compose -f compose.sqlite.yaml up -d
address=$(docker compose -f compose.sqlite.yaml port app 8000)
curl --retry 10 --retry-all-errors --retry-delay 1 -fsS -w '\n' "http://$address/"
docker compose -f compose.sqlite.yaml down
unset APP_PORT GREETING

`APP_PORT=0` попросит Docker выбрать свободный порт. После второго запуска поменялся `hostname`, счётчик остался равен 1. [Вывод запуска одного контейнера и Compose](logs/sqlite.txt).

Проверка Redis

Команды для отдельного проекта с пустым :

export APP_PORT=0 GREETING='Привет от Redis'
dc() { docker compose -p ms-redis-proof -f compose.yaml "$@"; }
dc up -d --build --wait
dc ps
url="http://$(dc port app 8000)"
curl -fsS -w '\n' "$url/"
curl -fsS -w '\n' -X POST "$url/increment"
curl -fsS -w '\n' -X POST "$url/increment"
curl -fsS -w '\n' "$url/"

dc down
dc up -d --wait
url="http://$(dc port app 8000)"
curl -fsS -w '\n' "$url/"

dc stop redis
curl -sS -w '\nHTTP %{http_code}\n' "$url/healthz"
curl -sS -w '\nHTTP %{http_code}\n' "$url/readyz"
curl -sS -w '\nHTTP %{http_code}\n' -X POST "$url/increment"

dc start redis
curl --retry 10 --retry-delay 1 --retry-max-time 25 --max-time 3 \
  -fsS -w '\nHTTP %{http_code}\n' "$url/readyz"
curl -fsS -w '\n' "$url/"
curl -fsS -w '\n' -X POST "$url/increment"
dc down
unset APP_PORT GREETING

После двух POST счётчик был 2. После `down` и `up` он остался 2. С выключенным Redis `/healthz` вернул 200, а `/readyz` и POST вернули 503. После запуска Redis `/readyz` снова вернул 200, GET показал 2, следующий POST показал 3.
