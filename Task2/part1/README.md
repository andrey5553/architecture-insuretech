# Инструкции по запуску

### 1. Для того, чтобы запустить тесты locust в сервисе, выполните:
```bash
minikube start --addons=metrics-server
minikube addons enable metrics-server

# Проверка наличия сервиса в подах
kubectl get pods -n kube-system | findstr metrics-server

kubectl create namespace monitoring
kubectl apply -f service.yaml
kubectl apply -f deployment.yaml
kubectl apply -f hpa.yaml

# Запуск приложения в браузере
minikube service scaletestapp-service
# Проверка деплоймента для hpa
kubectl get hpa 

# Скачиваем locust
pip install locust

# Проброс портов
kubectl port-forward service/scaletestapp-service 8080:8080

# Запуск locust тестов (скрипт на powershell)
start_locust.ps1

# Краткий анализ результатов:
  * Целевой хост: http://localhost:8080
  * Всего запросов: 59 951
  * Ошибок: 0 (Failures 0%)
  * RPS (запросов в секунду): 195.7
  * Среднее время ответа: 6.79 мс
  * 95-й перцентиль: 15 мс (95% запросов выполнились быстрее 15 мс)
  * Максимальное время: 224 мс

[Статистика](/images/статистика%20locust.png)

# Дашборда k8s 
[Статус текущий](/images/dashboard%20-%20статус%20сервиса.png)
```

### 2. Для того, чтобы получить Prometheus метрики, выполните п.1 и команды:
```bash
helm repo add prometheus-community "https://prometheus-community.github.io/helm-charts"
helm repo update
helm install prometheus-operator prometheus-community/kube-prometheus-stack --namespace monitoring

kubectl apply -f service-monitor.yaml
kubectl apply -f prometheus.yaml
kubectl apply -f prometheus-operator.yaml

helm install prometheus-adapter prometheus-community/prometheus-adapter --namespace monitoring --values values.yaml

# Ждем пока все поды стартанут
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1

# Проброс портов
kubectl port-forward service/scaletestapp-service 8080:8080

# Запуск locust тестов
locust -H `minikube service scaletestapp-service --url` -u 1000 -t 10m --headless --logfile locust.log --json-file locust_result --only-summary > locust.log 2>&1

# Отображаем список сущностью для prometeus (для поиска нужной поды и запуска прометеус в браузере)
kubectl get svc -A | findstr prometheus

# Запуск прометеус в браузере
minikube service prometheus-operator-kube-p-prometheus -n monitoring

# Проброс портов для запуска прометеус 
kubectl port-forward svc/prometheus-operator-kube-p-prometheus -n monitoring 9090:9090

# Открываем браузере с прометеус и смотрим метрики (http://localhost:9090/targets?pool=&search=scaletestapp)

[Перечисление метрик приложения (часть списка)](/part2/images/scaleapp%20-%20метрики%20(перечисление).png)
[Прометеус - поиск нашего приложения в таргет (проверка того, что метрики пишем)](/part2/images/прометеус%20-%20таргет%20-%20scaleapp%20(приложение).png)

* http_requests_total
  - Метрика http_requests_total доступна и имеет значение около 180,000
  - Данные собираются и отображаются на графике
  - Метрика имеет правильные лейблы:
    container="ScaleTapestry"
    endpoint="http"
    instance="10.244.0.4:8087"
    job="scaleTapestry-service"
    namespace="default"
    pod="scaleTapestry-78b37f6999-mzmdm"
    service="ScaleTapestry-service"

  [http_requests_total метрика](/part2/images/прометеус%20-%20метрика%20-%20http_requests_total.png)
  [http_requests_total метрика таблица](/part2/images/прометеус%20-%20метрика%20-%20http_requests_total%20(табличное%20представление).png)
```


  
