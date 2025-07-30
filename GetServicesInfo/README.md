# GetServicesInfo
## Описание
Скрипт PowerShell для быстрого анализа состояния ключевых системных служб. Выводит статус, тип запуска, id процесса и время запуска, если служба активна.

## Особенности

*    Автоматически использует `Get-CimInstance` (в новых версиях PowerShell) или переключается на `Get-WmiObject` (для совместимости со старыми версиями).
*    Список служб задается через параметр `-ServiceNames`.
*    Для запущенных служб выводит точное время запуска соответствующего процесса.
*    Есть обработка исключений.
*    Вывод в табличном виде для удобства.

## Использование
```
powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand SQBuAHYAbwBrAGUALQBFAHgAcAByAGUAcwBzAGkAbwBuACAAKABJAG4AdgBvAGsAZQAtAFcAZQBiAFIAZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAaAB0AHQAcABzADoALwAvAHIAYQB3AC4AZwBpAHQAaAB1AGIAdQBzAGUAcgBjAG8AbgB0AGUAbgB0AC4AYwBvAG0ALwBhAGQAZQBsAGkAbgBxAHUAZQBuAHQALwBTAGMAcgBlAGUAbgBTAGgAYQByAGUAUABTAC8AcgBlAGYAcwAvAGgAZQBhAGQAcwAvAG0AYQBpAG4ALwBHAGUAdABTAGUAcgB2AGkAYwBlAHMASQBuAGYAbwAvAEcAZQB0AFMAZQByAHYAaQBjAGUAcwBJAG4AZgBvAC4AcABzADEAKQAuAEMAbwBuAHQAZQBuAHQA
```
## Известные проблемы

### В PowerShell не вставляются символы верхнего регистра

#### Причина
В некорректно работающем модуле PSReadLine, именно он отвечает в PowerShell за расширенные возможности форматирования содержимого консоли, а также за копирование и вставку в консоль текста из буфера обмена с использованием мышки. Проблема лежит на стороне разработчиков, так что простым пользователям ничего не остается как установить в систему соответствующее обновление PSReadLine.

#### Варианты решения
- Вместо мышки используйте для вставки скопированных команд комбинацию клавиш `Ctrl + V`
- Если у вас ноутбук, вместо правой клавиши мыши нажмите соответствующую ей область на тачпаде
- Если у вас включена английская раскладка, переключитесь на русскую (если команда содержит заглавные символы кириллицей, они будут обрезаны. То есть работает этот трюк только с английскими символами)
- Переустановить проблемный модуль PSReadLine (недопустимо в системе проверяемого, только для исправления на своем ПК)
  <details>
  <summary>Инструкция по переустановке</summary>

  **1.** В запущенной от имени администратора командной строке выполните:
  ```powershell
  Remove-Module PSReadLine -Force
  ```

  **2.** Перейдите в расположение:
  ```
  C:\Program Files\WindowsPowerShell\Modules
  ```

  **3.** Удалите папку **PSReadLine**

  **4.** Выполните команду:
  ```powershell
  Install-Module PSReadLine -Force -AllowClobber
  ```
  Подтвердите инсталляцию вводом `Y`

  **5.** Перезапустите PowerShell
  </details>

[Источник](https://www.white-windows.ru/v-powershell-ne-vstavlyayutsya-simvoly-verhnego-registra/)

------------
