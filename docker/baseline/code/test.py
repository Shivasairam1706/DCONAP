'''
docker compose -f docker-compose.yml --profile dev build --no-cache
docker compose -f docker-compose.yml --profile dev up -d
docker compose -f docker-compose.yml logs dev
'''
docker compose up --build -d development spark-master spark-worker prometheus grafana \
postgres redis gitlab airflow zookeeper kafka flink-jobmanager flink-taskmanager superset
