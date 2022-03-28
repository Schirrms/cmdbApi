# Warning

Chinese to English trouhgh Google Traduction (Schirrms) 

# This directory is the script of the iTop plugin action-shell-exec

The action sets the SCRIPT_NAME variable as the php script to be executed, and then uses a unified shell script as the wrapping script to asynchronously call the php script. In addition, the unified shell script also needs other unified variable names (mainly convenient for debugging, such as output in the log) Ticket id or server host name), so iTop should use `variable name=value` to define variables when setting action parameters. The list of variables is as follows

| variable name | variable value |
| ----- | ------ |
| SCRIPT_NAME | example.php |
| ID | $this->ref$(ticket), $this->friendlyname$(FunctinalCI) |
| TITLE | $this->title$(ticket), $this->hostname$(FunctinalCI) |
| DEBUG | true or false, update_functionalci_contacts.php supports this variable to delay the update to prevent the impact of caching, when set to true, it is used to cancel the delay when manually updating from the command line |

Note that the logs directory requires writable permissions, it is best to change the owner of the actions directory to the php running account

## Plugin introduction
To execute the action of the script, you need to open the shell_exec function in php

Fork from https://github.com/itop-itsm-ru/action-shell-exec

demo script(shell)

````
#!/bin/bash
d=`cd $(dirname $0);pwd`
cd $d
ds=`date +%Y%m%d-%H%M%S`

echo "$ds $THIS_NAME - $THIS_HOSTNAME"
echo "$ds $THIS_NAME - $THIS_HOSTNAME" >> demo.log
````

demo script(php). Need to read environment variables

````
#!/usr/bin/php
<?
$THIS_HOSTNAME = getenv("THIS_HOSTNAME");
$THIS_NAME = getenv("THIS_NAME");
echo "$THIS_HOSTNAME $THIS_NAME";
?>
````

### Asynchronous tasks

Suppose the script takes a long time to execute

````
#!/usr/bin/php
<?
$THIS_HOSTNAME = getenv("THIS_HOSTNAME");
$THIS_NAME = getenv("THIS_NAME");
$log = "php.log";
sleep(15);
file_put_contents($log, "$THIS_HOSTNAME $THIS_NAME\n", FILE_APPEND);
?>
````

As shown in the above code, it is actually measured that the front end of itop needs to wait between 15 and 16 seconds, so consider wrapping it with shell script to realize asynchronous execution of real tasks in the background

````
#!/bin/bash
d=`cd $(dirname $0);pwd`
cd $d
ds=`date +%Y%m%d-%H%M%S`

echo "$ds $THIS_NAME - $THIS_HOSTNAME"
echo "$ds $THIS_NAME - $THIS_HOSTNAME" >> demo.log
#./demo.php & # This approach is invalid, the next line is required (starting the subscript, you must use & and specify the output (has to be directed to /dev/null)
./demo.php &>/dev/null &
````

### custom variables
Modified the plugin to support custom variables, e.g. define `SCRIPT_NAME=demo.php`, then call `./$SCRIPT_NAME &>/dev/null &` in the shell script, this avoids the need for every async php The script repeats the shell-wrapped script.

Note that variables are defined without quotation marks, the plugin will automatically add quotation marks.

### 2.3.3 rest api patch
task/ticket_robot.php needs to take service_details, the rest api of 2.3.3 does not support AttributeCustom type Fields, it needs to be patched (itop_restapi_2.3.3.patch), copy the patch file to the iTop root directory, and execute patch -p0 < itop_restapi_2.3.3. patch

## task corresponding trigger action reference

### Action
````
Name,Category,Name,Description,Status,Path,Parameters
ticket_robot,Script execution,ticket_robot,ticket operation,production,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=ticket_robot.php ID=$this->id$
update_accounts_cache-lnkContactToFunctionalCI,Script execution,update_accounts_cache-lnkContactToFunctionalCI,update server account cache,in production,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_accounts_cache.php ID=$this->functionalci_id$
update_accounts_cache-lnkUserToServer,Script execution,update_accounts_cache-lnkUserToServer,update server account cache,in production,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_accounts_cache.php ID=$this->server_id$
update_accounts_cache-Server,Script execution,update_accounts_cache-Server,update server account cache,in production,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_accounts_cache.php ID=$this->id$
update_functionalci_contacts, Script execution, update_functionalci_contacts, update the contacts field of domain name, app, database, etc., in production, /wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_functionalci_contacts.php ID=$this->applicationsolution_id$
update_server_contacts,Script execution,update_server_contacts,update server contacts,in production,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_server_contacts.php ID=$this->functionalci_id$
````

###update_functionalci_contacts
````
description, category, target class, filter
lnkApplicationSolutionToFunctionalCI delete, trigger (when the object is deleted), lnkApplicationSolutionToFunctionalCI, SELECT lnkApplicationSolutionToFunctionalCI WHERE functionalci_id_finalclass_recall NOT IN ('ApplicationSolution', 'Server')
lnkContactToApplicationSolution delete, trigger (when object is deleted), lnkContactToApplicationSolution, SELECT lnkContactToApplicationSolution
lnkApplicationSolutionToFunctionalCI create, trigger (object creation time), lnkApplicationSolutionToFunctionalCI, SELECT lnkApplicationSolutionToFunctionalCI WHERE functionalci_id_finalclass_recall NOT IN ('ApplicationSolution', 'Server')
lnkContactToApplicationSolution creation, trigger (when object is created), lnkContactToApplicationSolution, SELECT lnkContactToApplicationSolution
````

### update_server_contacts
````
description, category, target class, filter
Server lnkContact Create, Trigger (when object is created), lnkContactToFunctionalCI, SELECT lnkContactToFunctionalCI WHERE functionalci_id_finalclass_recall='Server'
Server lnkContact delete, trigger (when object is deleted), lnkContactToFunctionalCI, SELECT lnkContactToFunctionalCI WHERE functionalci_id_finalclass_recall='Server'
````

### ticket_robot
````
description, category, target class, filter
A new ticket is created, trigger (when object is created), Ticket, SELECT Ticket AS t WHERE t.finalclass IN ('UserRequest','Incident')

description, target class, state, category, filter
Ticket is closed, Ticket, closed, trigger (when entering a state), SELECT Ticket AS t WHERE t.finalclass IN ('UserRequest','Incident')
Ticket has been resolved, Ticket, resolved, trigger (when entering a state), SELECT Ticket AS t WHERE t.finalclass IN ('UserRequest','Incident')
Ticket is rejected, Ticket, rejected, trigger (when entering a state), SELECT Ticket AS t WHERE t.finalclass IN ('UserRequest','Incident')
````

### update_accounts_cache-lnkContactToFunctionalCI
````
description, category, target class, filter
Server lnkContact delete, trigger (when object is deleted), lnkContactToFunctionalCI, SELECT lnkContactToFunctionalCI WHERE functionalci_id_finalclass_recall='Server'
Server lnkContact Create, Trigger (when object is created), lnkContactToFunctionalCI, SELECT lnkContactToFunctionalCI WHERE functionalci_id_finalclass_recall='Server'
````

### update_accounts_cache-lnkUserToServer
````
description, category, target class, Tracked attributes, filter
ln 

# Original Version

# 此目录为iTop插件action-shell-exec的脚本

action设置SCRIPT_NAME变量为要执行的php脚本，然后使用一个统一的shell脚本作为包裹脚本来异步调用php脚本. 另外，统一的shell脚本还需要其他统一的变量名(主要方便调试，例如在日志中输出工单id或者服务器主机名)，因此iTop设置action parameters时要使用`变量名=值`的方式定义变量，变量列表如下

| 变量名 | 变量值 |
| -----  | ------ |
| SCRIPT_NAME | example.php |
| ID | $this->ref$(工单), $this->friendlyname$(FunctinalCI) |
| TITLE | $this->title$(工单), $this->hostname$(FunctinalCI) |
| DEBUG | true or false, update_functionalci_contacts.php 支持此变量，用于延迟更新，防止缓存造成的影响, 当设置为true时，用于命令行手动更新时取消延迟 |

注意 logs目录需要可写权限，最好将actions目录属主改为php运行账号

## 插件介绍
执行脚本的动作, 需要php开启shell_exec函数

Fork from https://github.com/itop-itsm-ru/action-shell-exec

demo script(shell)

```
#!/bin/bash
d=`cd $(dirname $0);pwd`
cd $d
ds=`date +%Y%m%d-%H%M%S`

echo "$ds  $THIS_NAME - $THIS_HOSTNAME"
echo "$ds  $THIS_NAME - $THIS_HOSTNAME" >> demo.log
```

demo script(php). 需要读取环境变量

```
#!/usr/bin/php
<?
$THIS_HOSTNAME = getenv("THIS_HOSTNAME");
$THIS_NAME = getenv("THIS_NAME");
echo "$THIS_HOSTNAME $THIS_NAME";
?>
```

### 异步任务

假设脚本需要执行很长时间

```
#!/usr/bin/php
<?
$THIS_HOSTNAME = getenv("THIS_HOSTNAME");
$THIS_NAME = getenv("THIS_NAME");
$log = "php.log";
sleep(15);
file_put_contents($log, "$THIS_HOSTNAME $THIS_NAME\n", FILE_APPEND);
?>
```

如上代码，实测此时itop前端要等待15至16秒之间，因此考虑用shell脚本包裹一下，实现后台异步执行真正的任务

```
#!/bin/bash
d=`cd $(dirname $0);pwd`
cd $d
ds=`date +%Y%m%d-%H%M%S`

echo "$ds  $THIS_NAME - $THIS_HOSTNAME"
echo "$ds  $THIS_NAME - $THIS_HOSTNAME" >> demo.log
#./demo.php &   # 这种做法无效，需要下一行那样(启动子脚本，必须要使用&和指定输出(只好是定向到/dev/null)
./demo.php &>/dev/null  &
```

### 自定义变量
对插件做了修改，支持自定义变量，例如定义 `SCRIPT_NAME=demo.php`，然后在shell脚本中调用 `./$SCRIPT_NAME &>/dev/null &`，这样做可以避免为每一个异步php脚本重复写shell包裹脚本.

注意，变量定义时不要带引号，插件会自动加上引号。

### 2.3.3 rest api 补丁
task/ticket_robot.php 需要 取service_details, 2.3.3的rest api不支持AttributeCustom类型的Fields，需要打补丁（itop_restapi_2.3.3.patch），复制补丁文件到iTop根目录，执行 patch -p0 < itop_restapi_2.3.3.patch

## task对应触发器动作参考

### 动作
```
名称,类别,名称,描述,状态,Path,Parameters
ticket_robot,Script execution,ticket_robot,工单操作,生产中,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=ticket_robot.php ID=$this->id$
update_accounts_cache-lnkContactToFunctionalCI,Script execution,update_accounts_cache-lnkContactToFunctionalCI,更新服务器账号缓存,生产中,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_accounts_cache.php ID=$this->functionalci_id$
update_accounts_cache-lnkUserToServer,Script execution,update_accounts_cache-lnkUserToServer,更新服务器账号缓存,生产中,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_accounts_cache.php ID=$this->server_id$
update_accounts_cache-Server,Script execution,update_accounts_cache-Server,更新服务器账号缓存,生产中,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_accounts_cache.php ID=$this->id$
update_functionalci_contacts,Script execution,update_functionalci_contacts,更新域名，app，数据库等的contacts字段,生产中,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_functionalci_contacts.php  ID=$this->applicationsolution_id$
update_server_contacts,Script execution,update_server_contacts,更新服务器联系人,生产中,/wwwroot/cmdbApi/actions/demo.sh,SCRIPT_NAME=update_server_contacts.php ID=$this->functionalci_id$
```

### update_functionalci_contacts
```
描述,类别,目标类,过滤器
lnkApplicationSolutionToFunctionalCI 删除,触发器(对象删除时),lnkApplicationSolutionToFunctionalCI,SELECT lnkApplicationSolutionToFunctionalCI WHERE functionalci_id_finalclass_recall NOT IN ('ApplicationSolution', 'Server')
lnkContactToApplicationSolution删除,触发器(对象删除时),lnkContactToApplicationSolution,SELECT lnkContactToApplicationSolution
lnkApplicationSolutionToFunctionalCI创建,触发器 (对象创建时),lnkApplicationSolutionToFunctionalCI,SELECT lnkApplicationSolutionToFunctionalCI WHERE functionalci_id_finalclass_recall NOT IN ('ApplicationSolution', 'Server')
lnkContactToApplicationSolution创建,触发器 (对象创建时),lnkContactToApplicationSolution,SELECT lnkContactToApplicationSolution
```

### update_server_contacts
```
描述,类别,目标类,过滤器
服务器lnkContact创建,触发器 (对象创建时),lnkContactToFunctionalCI,SELECT lnkContactToFunctionalCI WHERE functionalci_id_finalclass_recall='Server'
服务器lnkContact删除,触发器(对象删除时),lnkContactToFunctionalCI,SELECT lnkContactToFunctionalCI WHERE functionalci_id_finalclass_recall='Server'
```

### ticket_robot
```
描述,类别,目标类,过滤器
新工单被创建,触发器 (对象创建时),Ticket,SELECT Ticket AS t WHERE t.finalclass IN ('UserRequest','Incident')

描述,目标类,状态,类别,过滤器
工单已关闭,Ticket,closed,触发器 (进入一个状态时),SELECT Ticket AS t WHERE t.finalclass IN ('UserRequest','Incident')
工单已解决,Ticket,resolved,触发器 (进入一个状态时),SELECT Ticket AS t WHERE t.finalclass IN ('UserRequest','Incident')
工单被驳回,Ticket,rejected,触发器 (进入一个状态时),SELECT Ticket AS t WHERE t.finalclass IN ('UserRequest','Incident')
```

### update_accounts_cache-lnkContactToFunctionalCI
```
描述,类别,目标类,过滤器
服务器lnkContact删除,触发器(对象删除时),lnkContactToFunctionalCI,SELECT lnkContactToFunctionalCI WHERE functionalci_id_finalclass_recall='Server'
服务器lnkContact创建,触发器 (对象创建时),lnkContactToFunctionalCI,SELECT lnkContactToFunctionalCI WHERE functionalci_id_finalclass_recall='Server'
```

### update_accounts_cache-lnkUserToServer
```
描述,类别,目标类,Tracked attributes,过滤器
lnkUserToServer删除,触发器(对象删除时),lnkUserToServer,
lnkUserToServer创建,触发器 (对象创建时),lnkUserToServer,

描述,类别,目标类,Tracked attributes,过滤器
lnkUserToServer更新,Trigger on object update,lnkUserToServer,status,
```

### update_accounts_cache-Server
```
描述,类别,目标类,Tracked attributes,过滤器
服务器use_pam更新,Trigger on object update,Server,use_pam,
```