# Краткое описание lapssswp
[![english](https://img.shields.io/badge/read_in-english-blue.svg)](README.md)
[![русском](https://img.shields.io/badge/%D1%87%D0%B8%D1%82%D0%B0%D1%82%D1%8C_%D0%BD%D0%B0-%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%BE%D0%BC-lightblue.svg)](README.ru-RU.md)  
---
lapssswp позволяет пользователям получать доступ к паролю локального администратора своего устройства с помощью запроса на портале самообслуживания.

![Экран входа](./demo_images/logonscreen_ru.png?raw=true "Экран входа")
![Главная](./demo_images/main_page_ru.png?raw=true "Главная")
![Мои устройства](./demo_images/my_devices_ru.png?raw=true "Мои устройства")
![Мои устройства дисклеймер](./demo_images/my_devices_show_disclaimer_ru.png?raw=true "Мои устройства дисклеймер")
![Мои устройства отображение пароля](./demo_images/my_devices_show_display_ru.png?raw=true "Мои устройства отображение пароля")

## Почему lapssswp
lapssswp расшифровывается как `Local Admistrator Password Solution Self Service Web Portal`. 

## Возможности lapssswp
- Доменная аутентификация
- Работа в https или http режиме (для reverse-proxy) 
- Поддержка Windows LAPS
- Поддержка Microsoft LAPS
- Поддержка нескольких языков (en, ru, возможность добавления новых локализаций)
- Определение и переключение на предпочитаемый язык в браузере пользователя.

## Общие условия для использования портала lapssswp
- Устройства с операционной системой Windows находятся в домене Active Directory. 
- Пользователи портала являются доменными учетными записями и так же членами одной из специальных доменных групп. 
- В домене настроен Microsoft LAPS или более новое встроенное решение Windows LAPS.
- Устройства являются клиентами SCCM и в нем настроен механизм определения user-device affinity, либо отношение пользователей к устройствам задано в SCCM вручную.

## Условия необходимые для запуска lapssswp
- Windows Server / Workstation
- Powershell 7
- Powershell Module Pode
- Powershell Module Active Directory
- Powershell Module LAPS (для Microsoft LAPS, который не является встроенным в Active Directory, как Windows LAPS)
- Доменная сервисная учётная запись с необходимым правами в SCCM, Active Directory, Microsoft LAPS/Windows LAPS и правами локального администратора на сервере, где будет работать lapssswp. 

# Вопросы и ответы
## Какие пользователи имеют права на просмотр пароля локального администратора? 
Пользователи находящиеся в заданных доменных группах. Можно задать произвольные имена групп для администраторов и обычных пользователей lapssswp в файле server.psm1.

## Пароли каких устройств могут быть отображены? 
Отображаются только пароли локальных администраторов устройств, находящихся в пределах Organizational Unit, указанной в файле server.psm1. 

## Чем отличаются права администраторов? 
Пользователи из доменной группы администраторов lapssswp могут просматривать пароли всех устройств в пределах Organizational Unit заданного в файле server.psm1.

## Как определяются устройства на которые пользователь имеет права просмотра пароля?
Для определения устройств пользователя используется запрос к SCCM с целью получения списка device affinity.
lapssswp учитывает устройства которые были назначены пользователю автоматически (по прошествии некоторого времени использования) или вручную заданы администратором SCCM.

# Установка lapssswp
## Подготовка файлов
- Расположить файлы проекта в произвольной дирректории, например  `C:\lapssswp`
- Отредактировать файл server.psm1, задав необходимые настройки.
- Отредактировать файл localiztion_footer.json, описав необходимые ссылки которые будут отображаться в нижней части портала.
## Запуск вручную из консоли
Файл server.ps1 необходимо запускать из Powershell 7 (pwsh.exe).
Powershell 7 должен быть запущен с правами администратора и от доменной учетной записи, которая имеет необходимые права. Подробнее о правах в блоке `Права необходимые сервисной учетной записи`.
### Запуск Powershell 7 от администратора
- Установить Powershell 7 (https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)
- Убедиться что сервисная учетная запись имеет права локального администратора на устройстве.
- Запустить Powershell 7 от имени сервисной учетной записи.
- Выполнить `Start-Process pwsh -Verb RunAs`, подтвердить UAC, если он включен.
### Запуск lapssswp портала
- Выполнить `cd C:\lapssswp` или измените путь на другой каталог содержащий файлы портала.
- Выполнить `& .\server.ps1`
- Перейти на https://localhost/ или https://localhost:<port>

# Запуск lapssswp в качестве службы Windows
Для запуска портала в качестве службы Windows можно использовать [NSSM](https://nssm.cc/)
## Регистрация службы lapssswp
```Powershell
# Располозить nssm.exe в папке 'nssm' внутри проекта проекта
cd C:\lapssswp\nssm
& .\nssm.exe install lapssswp 'C:\Program Files\PowerShell\7\pwsh.exe' '-File .\server.ps1'
& .\nssm.exe set lapssswp DisplayName 'lapssswp'
& .\nssm.exe set lapssswp Description 'lapssswp.mycompany.com web portal. Written on Powershell web framework Pode. Service is installed using NSSM.'
& .\nssm.exe set lapssswp ImagePath 'C:\lapssswp\nssm\nssm.exe'
& .\nssm.exe set lapssswp AppDirectory 'C:\lapssswp'
& .\nssm.exe set lapssswp Start SERVICE_DELAYED_AUTO_START
& .\nssm.exe set lapssswp ObjectName MYCOMPANY\lapssswp_service_account <lapssswp_service_account_password>
& .\nssm.exe start lapssswp
```
### Удаление службы lapssswp
```Powershell
cd C:\lapssswp\nssm
& .\nssm.exe stop lapssswp
& .\nssm.exe remove lapssswp confirm
```

# Права необходимые сервисной учетной записи
## SCCM
### Простой вариант с негрануливанным доступом
Выдать учетной записи права администратора на SCCM.
### Усложненный вариант с гранулированным доступом
- Создать отдельную роль с правами `User Device Affinities – Read`.
## Microsoft LAPS
Если в домене настроен Microsoft LAPS, то выдать сервисной учетной записи необходимые права используя командлеты из модуля LAPS.
## Windows LAPS
Если в домене настрое Windows LAPS, то достаточно делегировать сервисной учетной записи права на чтение атрибута `ms-Mcs-AdmPwd` и на редактирование `ms-Mcs-AdmPwdExpirationTime` для компьютеров в необходимом Organizational Unit.