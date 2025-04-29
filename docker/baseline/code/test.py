'''
docker compose up --build -d development spark-master spark-worker prometheus grafana \
postgres redis gitlab airflow zookeeper kafka flink-jobmanager flink-taskmanager superset
'''
string = 'abccdef'

print(string[:len(string)])
