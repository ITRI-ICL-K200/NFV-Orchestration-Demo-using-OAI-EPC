# How to install OpenBaton

## OS
* ubuntu 16.04

## pre install 
* sudo apt-get install curl

## install OpenBatonb
* install Open Baton: sh <(curl -s http://get.openbaton.org/bootstrap) release
* install step:
 * 1. 選擇Open Baton NFVO版本，推薦5.1.1 for ubuntu 16.04
 * 2. 選擇RabbitMQ broker IP，此IP必須是VIM中VM能夠PING通的位置
 * 3. 選擇RabbitMQ broker PORT，用預設值即可(15672)
 * 4. 設定登入GUI帳戶"admin"的密碼
 * 5. 重複登入GUI帳戶"admin"的密碼
 * 6. 使否使用MySQL，不使用選NO，使用選YES，此後安裝任何套件皆需要設定MySQL的使用者和密碼
 * 7. 選擇啟動HTTPS
 * 8. 選擇安裝OpenStack VIM Driver Plugin，版本5.1.1
 * 9. 選擇安裝VNFM Generic，版本5.1.1
 * 10. Fault Management System可不安裝，有需要再安裝即可，版本1.4.0
 * 11. Auto Scaling Engine可不安裝，有需要再安裝即可，需要給Zabbix IP/usernmae/password/nfvo IP <-- 作者沒有試過這個功能
 * 12. Network Slicing Engine可不安裝，有需要再安裝即可，版本1.1.2 
 * 13. 重開機
 * 若出現此訊息，直接忽略: This is nc from the netcat-openbsd package. An alternative nc is available in the netcat-traditional package.
 * configure檔案會記錄剛剛設定的IP/PORT/PASSWORD... 之類的參數，若要修改任何參數即修改此configure檔案即可
 * configure檔案位置: /etc/openbaton/openbaton-nfvo.properties

## configure檔案參數
* nfvo.rabbit.brokerIp: RabbitMQ broker IP
* nfvo.rabbit.management.port: RabbitMQ broker PORT
* nfvo.delete.all-status: 任何狀態的VM都能被移除(True/False)
* nfvo.security.admin.password: 登入GUI帳戶"admin"的密碼
* nfvo.monitoring.ip: the Zabbix server ip

## 啟動與停止OpenBaton
* 啟動/停止OpenBaton需要啟動/停止nfvo和vnfm
 * nfvo

 ~~~
啟動: sudo openbaton-nfvo start
停止: sudo openbaton-nfvo stop
 ~~~
 * vnfm

 ~~~
啟動: sudo openbaton-vnfm-generic start
停止: sudo openbaton-vnfm-generic stop
 ~~~

## 確認OpenBaton是否正常運作
* 在瀏覽器上輸入"安裝OpenBaton機器的網址:8080"，進入GUI介面
* 完成OpenBaton Tutorial: Dummy Network Service Record --> http://openbaton.github.io/documentation/dummy-NSR/
* 若缺少Test vim driver，到 https://github.com/openbaton/test-plugin 中安裝driver，然後重開機
* 若執行完上述步驟，看Network Service Records List of NSRs中，若State為ACTIVE 即為成功


# How to install OpenStack by All-in-One
[OS]
> 只有 ubuntu 14.04 能正常安裝

[下載壓縮檔]
> devstack.tgz: https://drive.google.com/open?id=1MZZJuhdvUPH7ZN1xvqR9wASKfFSkJ990

> stack.tgz: https://drive.google.com/open?id=1YzkrgkZDQFEo8-1sdwIO9gyFDipc-O5G

[切換到root]
> sudo su

[安裝git]
> apt-get install git
> exit -->離開root

[建立stack使用者]
> 解壓縮devstack.tgz到/home/
> cd /home/devstack/tools/
> sudo ./create-stack-user.sh

[編輯stack用戶權限]
> sudo vi /etc/sudoers
> 內容如下:
> \# User privilege specification
> root ALL=(ALL:ALL) ALL
> stack ALL=(ALL:ALL) ALL

[修改/home/devstack權限]
> sudo su
> chown –R stack:stack /home/devstack
> chown –R stack:stack /opt/stack

[切換user到stack]
> su stack
> vi /home/devstack/local.conf
> 修改內容如下:
> > HOST_IP=對外的IP(能連到INTERNET的IP，EX:10.101.136.44)
> > FLOATING_RANGE=改成欲要分配給VM的IP網段(EX:"10.101.136.0/24")
> > Q_FLOATING_ALLOCATION_POOL=改成欲要分配給VM的IP區間(EX:start=10.101.136.120,end=10.101.136.134)
> > PUBLIC_NETWORK_GATEWAY=對外的IP的GATEWAY(EX:"10.101.136.254")
> > PUBLIC_INTERFACE=OpenStack對外的網卡

[安裝OpenStack]
> *此時使用者為stack，若不是stack執行su stack
> 1. 解壓所stack.tgz到/opt/
> 2. cd /home/devstack
> 3. ./stack.sh (這次安裝會失敗)
> 4. 遇到ERROR
> 　4.1 vim /usr/local/lib/python2.7/dist-packages/openstack/session.py
> 　4.2 去掉DEFAULT_USER_AGENT = "openstacksdk/%s" % openstack.__version__後面的.__version__
> 　4.3 移除OpenStack
> 5. ./stack.sh (這次能成功安裝)
> 6. 修正VNC不正常(當OpenStack UI上的雲實例中的主控台無法使用時，需執行以下指令修正)
> 　6.1 cd /opt/stack/noVNC
> 　6.2 git checkout v0.6.0
> *此後每次重開機都要執行./stack.sh，OpenStack才會啟動，且使用者為stack


[移除OpenStack]
> cd /home/devstack
> ./unstack.sh

[取得OpenStack tokens]
> curl -d '{"auth":{"passwordCredentials":{"username": "__YOUR_USER_NAME__", "password": "__YOUR_PASSWORD__"},"tenantName": "__YUOR_TENANT_NAME__"}}' -H "Content-Type: application/json" http://__YOUR_OPENSTACK_IP_ADRESS__:5000/v2.0/tokens



