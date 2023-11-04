# Инструкция для workshop 

# Оглавление


## Обязательные требования перед workshop
- :white_check_mark: убедиться, что вы получили по почте тестовую учетную запись в облаке
- :white_check_mark: установить и настроить [yc client](https://cloud.yandex.ru/docs/cli/quickstart)
- :white_check_mark: установить и настроить [git](https://git-scm.com/book/ru/v2/Введение-Установка-Git)
- :white_check_mark: установить [terraform](https://www.terraform.io/downloads.html)
- :white_check_mark: установить [jq](https://macappstore.org/jq/)
- :white_check_mark: установить [helm](https://helm.sh/docs/intro/install/)

## Первая часть - Audit Trails Demo

Шаг 0. **Проверить, что у вас настроен yc client**

Шаг 1. **Выполните команду** для скачивания файлов:
```
git clone https://github.com/yandex-cloud/yc-solution-library-for-security.git
``` 

Шаг 2. **Перейдите в папку** c первым демо:
```
cd ./yc-solution-library-for-security/auditlogs/export-auditlogs-to-ELK_main/workshop-guide/example/audit_trails_demo/ 
``` 

Шаг 3. **Выполнить команду** просмотра yc cli конфигурации:
```
yc config list
``` 

Шаг 4. **Скопируйте** вывод в файл private.auto.tfvars и замените ":" на "=" , "тире" на "нижнее подчеркивание" а также добавьте "" в значения переменных:
```
vim private.auto.tfvars
``` 

Шаг 5. **Выполнить команду** для инициализации terraform:
```
terraform init
``` 

Шаг 6. **Выполнить команду** и нажмите "yes":
```
terraform apply
``` 

Шаг 7. Не дожидаясь завершения **Зайдите в консоль облака** VPC -> провалитесь -> elk-subnet-a(...) -> Включить NAT в интернет

Шаг 8. **Сохраните значение elk_fqdn** из output - это адрес ELK (например, elk_fqdn = "https://c-enpj9n0h87pi99mh3r26.rw.mdb.yandexcloud.net")


Шаг 9. **Настройте Audit Trails**:
    - перейдите в audit trails (иконка в главном меню)
    - укажите имя
    - укажите сервисный аккаунт (trails-sa-...)
    - назначение: Object Storage
    - выберите Bucket (единственный)
    - префикс оставить пустым 
    - выбрать единственное облако
    - выберите в фильтре folder только свой каталог
    - создать

Шаг 10. **Подключитесь через браузер** к elk_fqdn (https://c-XXXXX.net) из п. 7

Шаг 11. **Укажите логин**: admin , пароль: ваш folder id (можно получить командой: yc config get folder-id)

#

## Вторая часть - Kubernetes Demo

Шаг 1. **Перейдите в папку**:
```
cd ../k8s_demo/example/
``` 

Шаг 2. **Создайте sa и назначьте ему права**:
```
yc iam service-account create terraform-sa-$(yc config get folder-id)
yc resource-manager folder add-access-binding --id=$(yc config get folder-id) --role=admin --subject=serviceAccount:$(yc iam service-account get --name terraform-sa-$(yc config get folder-id) --format json | jq -r '.id')
``` 

Шаг 3. **Выполните команду**:
```
yc iam key create --service-account-name terraform-sa-$(yc config get folder-id) --output key.json
``` 

Шаг 4. **Заполните файл provider.tf**:
    - cloud_id можно получить командой yc config get cloud-id  
    - folder_id можно получить командой yc config get folder-id  

Шаг 5. **Заполните файл main.tf**:
    - folder_id можно получить командой yc config get folder-id 
    - cluster_name можно получить yc managed-kubernetes cluster list --format json | jq -r '.[].name'
    - log_bucket_service_account_id можно получить yc iam service-account get --name terraform-sa-$(yc config get folder-id) --format json | jq -r '.id' 
    - log_bucket_name: создайте отдельный бакет Object Storage и назовите его "k8s-bucket-<ваш folder_id>", подставьте значение в переменную
    - elastic_server : подставьте значение вашего fqdn сервера Elastic из предидущего демо (можно быстро получить командой - echo https://c-$(yc managed-elasticsearch cluster get yc-elk-$(yc config get folder-id) --format=json | jq -r '.id').rw.mdb.yandexcloud.net)
    - coi_subnet_id: зайти в UI консоль и посмотреть id подсети elk-subnet-a
    - elastic_pw: укажите ваш folder_id (можно узнать с помощью команды yc config get folder-id )

Шаг 6. **Выполнить команду**:
```
terraform init
``` 

Шаг 7. **Выполнить команду** и нажмите "yes":
```
terraform apply
``` 

Шаг 8. **Для подключения к k8s кластеру выполните следующую команду**:
```
yc managed-kubernetes cluster get-credentials $(yc managed-kubernetes cluster list --format json | jq -r '.[].name') --external --force 
``` 

