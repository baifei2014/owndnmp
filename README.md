DNEP（Docker + Nginx + Elasticsearch + PHP7）是一款全功能的**LNEP一键安装程序**。


# 目录
- [1.目录结构](#1目录结构)
- [2.快速使用](#2快速使用)
- [3.PHP和扩展](#3PHP和扩展)
    - [3.1 切换Nginx使用的PHP版本](#31-切换Nginx使用的PHP版本)
    - [3.2 安装PHP扩展](#32-安装PHP扩展)
    - [3.3 Host中使用php命令行（php-cli）](#33-host中使用php命令行php-cli)
- [4.添加快捷命令](#4添加快捷命令)
- [5.使用Log](#5使用log)
    - [5.1 Nginx日志](#51-nginx日志)
    - [5.2 PHP-FPM日志](#52-php-fpm日志)


## 1.目录结构

```
/
├── conf                        配置文件目录
│   ├── conf.d                  Nginx用户站点配置目录
│   ├── nginx.conf              Nginx默认配置文件
│   ├── php-fpm.conf            PHP-FPM配置文件（部分会覆盖php.ini配置）
│   └── php.ini                 PHP默认配置文件
├── Dockerfile                  PHP镜像构建文件
├── log                         日志目录
├── docker-compose.yml   Docker 服务配置示例文件
└── www                         PHP代码目录
```


## 2.快速使用
1. 本地安装`git`、`docker`和`docker-compose`(**需要1.7.0及以上版本**)。
2. `clone`项目：
    ```
    $ git clone https://github.com/baifei2014/owndnmp
    ```
4. 启动：
    ```
    $ cd dnmp
    $ docker-compose up

5. 访问在浏览器中访问：`http://localhost`，PHP代码：`./www/localhost/index.php`文件。


6. 如需管理服务，请在命令后面加上服务器名称，dnmp支持的服务名有：`nginx`、`php72`, `elasticsearch`
```bash
$ docker-compose up                         # 创建并且启动所有容器
$ docker-compose up 服务1 服务2 ...         # 创建并且启动指定的多个容器
$ docker-compose up -d 服务1 服务2 ...      # 创建并且已后台运行的方式启动多个容器


$ docker-compose start 服务1 服务2 ...      # 启动服务
$ docker-compose stop 服务1 服务2 ...       # 停止服务
$ docker-compose restart 服务1 服务2 ...    # 重启服务
$ docker-compose build 服务1 服务2 ...      # 构建或者重新构建服务


$ docker-compose rm 服务1 服务2 ...         # 删除并且停止容器
$ docker-compose down 服务1 服务2 ...       # 停止并删除容器，网络，图像和挂载卷
```



```bash
$ docker exec -it dnmp_nginx_1 nginx -s reload
```
### 3.2 安装PHP扩展
PHP的很多功能都是通过扩展实现，而安装扩展是一个略费时间的过程，默认安装启用少量扩展。如果增加需要的PHP扩展直接修改Dockerfile文件。

启用扩展：
```bash
RUN docker-php-ext-install bcmath
```

从外部资源文件编译安装扩展：
```bash
RUN wget https://github.com/redis/hiredis/archive/v${HIREDIS_VERSION}.tar.gz -O hiredis.tar.gz \
    && mkdir -p hiredis \
    && tar -xf hiredis.tar.gz -C hiredis --strip-components=1 \
    && rm hiredis.tar.gz \
    && ( \
        cd hiredis \
        && make -j$(nproc) \
        && make install \
        && ldconfig \
    ) \
    && rm -r hiredis
```

然后重新build PHP镜像。
    ```bash
    docker-compose build php72
    docker-compose up -d
    ```
可用的扩展请看同文件的`PHP extensions`注释块说明。

### 3.3 Host中使用php命令行（php-cli）
1. 打开主机的 `~/.bashrc` 或者 `~/.zshrc` 文件，加上：
```bash
php () {
    tty=
    tty -s && tty=--tty
    docker run \
        $tty \
        --interactive \
        --rm \
        --volume $PWD:/var/www/html:rw \
        --workdir /var/www/html \
        dnmp_php72 php "$@"
}
```
2. 让文件起效：
```
source ~/.bashrc
```
3. 然后就可以在主机中执行php命令了：
```bash
~ php -v
PHP 7.2.13 (cli) (built: Dec 21 2018 02:22:47) ( NTS )
Copyright (c) 1997-2018 The PHP Group
Zend Engine v3.2.0, Copyright (c) 1998-2018 Zend Technologies
    with Zend OPcache v7.2.13, Copyright (c) 1999-2018, by Zend Technologies
    with Xdebug v2.6.1, Copyright (c) 2002-2018, by Derick Rethans
```

## 4.添加快捷命令
在开发的时候，我们可能经常使用`docker exec -it`切换到容器中，把常用的做成命令别名是个省事的方法。

打开~/.bashrc，加上：
```bash
alias dnginx='docker exec -it dnmp_nginx_1 /bin/sh'
alias dphp72='docker exec -it dnmp_php72_1 /bin/sh'
```

## 5.使用Log

Log文件生成的位置依赖于conf下各log配置的值。

### 5.1 Nginx日志
Nginx日志是我们用得最多的日志，所以我们单独放在根目录`log`下。

`log`会目录映射Nginx容器的`/var/log/nginx`目录，所以在Nginx配置文件中，需要输出log的位置，我们需要配置到`/var/log/nginx`目录，如：
```
error_log  /var/log/nginx/nginx.localhost.error.log  warn;
```


### 5.2 PHP-FPM日志
大部分情况下，PHP-FPM的日志都会输出到Nginx的日志中，所以不需要额外配置。

另外，建议直接在PHP中打开错误日志：
```php
error_reporting(E_ALL);
ini_set('error_reporting', 'on');
ini_set('display_errors', 'on');
```

如果确实需要，可按一下步骤开启（在容器中）。

1. 进入容器，创建日志文件并修改权限：
    ```bash
    $ docker exec -it dnmp_php_1 /bin/bash
    $ mkdir /var/log/php
    $ cd /var/log/php
    $ touch php-fpm.error.log
    $ chmod a+w php-fpm.error.log
    ```
2. 主机上打开并修改PHP-FPM的配置文件`conf/php-fpm.conf`，找到如下一行，删除注释，并改值为：
    ```
    php_admin_value[error_log] = /var/log/php/php-fpm.error.log
    ```
3. 重启PHP-FPM容器。


## License
MIT

