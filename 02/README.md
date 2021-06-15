# 2. Nomad Simple Cluster

## Nomad Server and 2 Clients

Nomad 서버 및 클라이언트 2개를 실행한다. 

Vagrant로 구성했으며 서버 구성은 `cluster.yaml`에 작성하였듯이 Server 1대, Client 2대로 구성할 예정이다.

```yaml
- name: nomad-server
  hostname: nomad-server
  box: bento/ubuntu-18.04
  ram: 1024
  ip: 172.17.8.101
- name: nomad-client01
  hostname: client-one
  box: bento/ubuntu-18.04
  ram: 1024
  ip: 172.17.8.102
- name: nomad-client02
  hostname: client-two
  box: bento/ubuntu-18.04
  ram: 1024
  ip: 172.17.8.103
```

Vagrant로 3개의 VM을 기동한다.  
```sh
$ vagrant up
```

server.hcl 구성 파일을 살펴보자. 에이전트를 `server`로 구성하고 클러스터에 하나의 서버를 구성함을 나타낸다. 실제 프로덕션 환경으로 가면 3-5개의 홀수개 클러스터로 구성을 권장한다. 그리고 API 및 서비스 간 통신을 위한 설정을 위해서 advertise 구문을 위에 설정한 IP로 작성하였다.  

```json
# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/tmp/server1"

# Enable the server
server {
    enabled = true

    # Self-elect, should be 3 or 5 for production
    bootstrap_expect = 1
}

# Advertise an accessible IP address so the server is reachable by other servers
# and clients. The IPs can be materialized by Terraform or be replaced by an
# init script.
advertise {
    http = "172.17.8.101:4646"
    rpc = "172.17.8.101:4647"
    serf = "172.17.8.101:4648"
}
```

그런 다음 명령을 실행하여 백그라운드에서 Nomad 서버를 시작한다.  
```sh
$ nomad agent -config /vagrant/server.hcl > nomad.log 2>&1 &
[1] 64533
```

Nomad 서버의 PID를 확인할 수 있다. `cat nomad.log`를 통해 를 실행하여 로그를 확인할 수 있다. 여기에는 "Nomad agent started!"라는 메시지를 포함한 로그들을 확인할 수 있다.  

client1.hcl와 client2.hcl 구성 파일을 확인한다. 에이전트를 `client`로 구성하고 `servers = ["172.17.8.101:4647"]` 구성을 보면 클러스터에 바라보는 server의 통신은 RPC포트인 4647 구성함을 나타낸다. 그리고 server와 동일하게 API 및 서비스 간 통신을 위한 설정을 위해서 advertise 구문을 위에 설정한 각각의 IP로 작성하였다.  

```json
# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/tmp/client"

# Enable the client
client {
    enabled = true

    # For demo assume we are talking to server1. For production,
    # this should be like "nomad.service.consul:4647" and a system
    # like Consul used for service discovery.
    servers = ["172.17.8.101:4647"]
}

# Advertise an accessible IP address so the server is reachable by other servers
# and clients. The IPs can be materialized by Terraform or be replaced by an
# init script.
advertise {
    http = "172.17.8.102:4646"
    rpc = "172.17.8.102:4647"
    serf = "172.17.8.102:4648"
}
```

client01에서 `client`를 실행한다.  
```sh
$ nomad agent -config /vagrant/client1.hcl > nomad.log 2>&1 &
[1] 21078
```

client02에서 `client`를 실행한다.  
```sh
$ nomad agent -config /vagrant/client2.hcl > nomad.log 2>&1 &
[1] 21111
```

두 `client` 모두 Nomad 서비스의 PID를 확인할 수 있다. `server`와 동일하게 `cat nomad.log`를 통해 를 실행하여 로그를 확인할 수 있다. 여기에는 "Nomad agent started!"라는 메시지를 포함한 로그들을 확인할 수 있다.  

## Job 실행하기

Nomad Job을 초기화한 다음 실행을 해본다. sample.nomad라는 샘플 작업 규격 파일을 생성한다. 

```
$ nomad job init -short
Example job file written to example.nomad
```

해당 명령을 실행하고 나면 아래와 같이 최소한의 HCL형태의 job specification 파일로 생성된다. -short 옵션 없이 실행하면 모든 설명을 포함하는 job spec이 생성될 것이다. init 명령은 Redis Docker 이미지를 배포하는 샘플 job spec을 생성하고 job group, job, Nomad Docker 드라이버, 리소스 요구 사항 및 Redis Docker 컨테이너 내에서 사용되는 포트정보와 Nomad가 동적으로 선택한 포트를 매핑하는 방법을 보여준다. 

job이 `example`이고 `cache`라고 하는 단일 task group이 있고, 해당 그룹에는 Docker 드라이버를 사용하여 표준 redis 이미지를 실행하는 "redis"라는 단일 태스트가 있음을 확인할 수 있다. 또한 job에는 500MHz CPU와 256MB의 메모리의 리소스를 선언하며, Nomad에서 동적으로 생성된 "db"라는 포트가 Docker 컨테이너 내부의 포트 6379에 매핑되어 있음을 알 수 있다.


```json
job "example" {
  datacenters = ["dc1"]

  group "cache" {
    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:3.2"

        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
```

## Job 실행 및 모니터링

nomad job plan 명령을 사용하여 nomad job을 dry-run 하고 검증된 버전의 job을 따로 실행할수 있다. 아직 실행되지 않은 job의 경우 중단될 위험이 없으므로 작업을 처음 실행할 때는 plan을 건너뛰는 것이 일반적이다. 

```sh
$ nomad job plan example.nomad
+/- Job: "example"
+/- Stop: "true" => "false"
    Task Group: "cache" (1 create)
      Task: "redis"

Scheduler dry-run:
- All tasks successfully allocated.

Job Modify Index: 24
To submit the job with version verification run:

nomad job run -check-index 24 example.nomad

When running the job with the check-index flag, the job will only be run if the
job modify index given matches the server-side version. If the index has
changed, another user has modified the job and the plan's results are
potentially invalid.
```

plan 없이 job을 실행한다. output을 보면 Evaluation ID 및 Allocation ID를 확인할 수 있다. 이후 사용되

```sh
$ nomad job run example.nomad
==> Monitoring evaluation "a0e6ef8b"
    Evaluation triggered by job "example"
    Evaluation within deployment: "c6940bea"
    Allocation "6085301b" created: node "eeff52e3", group "cache"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "a0e6ef8b" finished with status "complete"
```

`nomad job status example` 를 실행하면 job `example`의 ID와 Status, 실행 중인 데이터센터(DC) 등이 표시된다. 다음은 Task Group의 Summary (Queued, Starting, Running, Failed, Complete, Lost) 상태를 확인할 수 있고, 배포에 대한 정보, job allocation에 대한 히스토리를 확인할 수 있다. 

```sh
$ nomad job status example
ID            = example
Name          = example
Submit Date   = 2021-06-15T01:57:34Z
Type          = service
Priority      = 50
Datacenters   = dc1
Namespace     = default
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
cache       0       0         1        0       2         0

Latest Deployment
ID          = c6940bea
Status      = successful
Description = Deployment completed successfully

Deployed
Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
cache       1        1       1        0          2021-06-15T02:07:43Z

Allocations
ID        Node ID   Task Group  Version  Desired  Status    Created     Modified
6085301b  eeff52e3  cache       4        run      running   6m58s ago   6m47s ago
2fc03854  eeff52e3  cache       2        stop     complete  11m43s ago  7m29s ago
dd5eafbf  3a3dd316  cache       0        stop     complete  18m25s ago  16m40s ago
```

그런 다음 `eval status`명령을 통해 평가(Evaluation) 에 대한 자세한 정보를 얻을수 있다. `eval status`명령은 기존 평가에 대한 정보를 표시하는 데 사용된다. 평가에서 요청 된 모든 할당(Allocation)을 배치 할 수없는 경우 해당 명령을 사용하여 실패 이유를 확인할 수 있다. 현재 Status, Type, Job ID, Priority 등을 확인할 수 있다. 

```sh
$ nomad eval status a0e6ef8b
ID                 = a0e6ef8b
Create Time        = 2h6m ago
Modify Time        = 2h6m ago
Status             = complete
Status Description = complete
Type               = service
TriggeredBy        = job-register
Job ID             = example
Priority           = 50
Placement Failures = false
```

`nomad alloc status`를 통해 `redis` Task의 IP, Port, Resource, 최근 발생 event 등의 Allocation 상태를 확인할 수 있다.  


```sh
$ nomad alloc status 6085301b
ID                  = 6085301b-5722-b655-c470-8d25f9b9e686
Eval ID             = a0e6ef8b
Name                = example.cache[0]
Node ID             = eeff52e3
Node Name           = client-two
Job ID              = example
Job Version         = 4
Client Status       = running
Client Description  = Tasks are running
Desired Status      = run
Desired Description = <none>
Created             = 2h12m ago
Modified            = 2h11m ago
Deployment ID       = c6940bea
Deployment Health   = healthy

Allocation Addresses
Label  Dynamic  Address
*db    yes      10.0.2.15:28016 -> 6379

Task "redis" is "running"
Task Resources
CPU        Memory           Disk     Addresses
1/500 MHz  984 KiB/256 MiB  300 MiB

Task Events:
Started At     = 2021-06-15T01:57:33Z
Finished At    = N/A
Total Restarts = 0
Last Restart   = N/A

Recent Events:
Time                  Type        Description
2021-06-15T01:57:33Z  Started     Task started by client
2021-06-15T01:57:33Z  Task Setup  Building Task Directory
2021-06-15T01:57:33Z  Received    Task received by client
```

마지막으로 `nomad alloc logs` 명령을 통해 현재 마지막 allocation "redis" task에서 실행된 docker container의 Log를 확인할 수 있다. 

```sh
$ nomad alloc logs 6085301b redis
1:C 15 Jun 01:57:33.979 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 3.2.12 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 1
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           http://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

1:M 15 Jun 01:57:33.980 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
1:M 15 Jun 01:57:33.980 # Server started, Redis version 3.2.12
1:M 15 Jun 01:57:33.980 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
1:M 15 Jun 01:57:33.980 # WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
1:M 15 Jun 01:57:33.980 * The server is now ready to accept connections on port 6379
```

## Job 수정 및 재실행

Redis 데이터베이스에 트래픽이 많이 발생할 경우 부하 분산처리를 위해 더 많은 인스턴스를 실행해야하는 상황이 발생할 수 있다. 

job specification 인 `sample.nomad` 파일을 편집하여 작업 태스크 그룹의 카운트를 3으로 설정한다. 

```json
group "cache" {
  count = 3
```

Nomad에서 업데이트 되는 job의 상태를 미리 확인하기 위해 `nomad job plan` 명령을 실행한다.   

스케줄러가 Count 변경을 감지하여 2개의 새 allocation이 생성됨을 알려준다. `in-place`는 job spec을 기존 allocation으로 업데이트하지만 서비스 중단을 일으키지는 않는다. dry-run 결과에서는 "All tasks successfully allocated."를 통해 수정된 작업을 실행할 수 있는 충분한 리소스가 있음을 알수 있다.


```sh
$ nomad job plan example.nomad
+/- Job: "example"
+/- Task Group: "cache" (2 create, 1 in-place update)
  +/- Count: "1" => "3" (forces create)
      Task: "redis"

Scheduler dry-run:
- All tasks successfully allocated.

Job Modify Index: 54
To submit the job with version verification run:

nomad job run -check-index 54 example.nomad

When running the job with the check-index flag, the job will only be run if the
job modify index given matches the server-side version. If the index has
changed, another user has modified the job and the plan's results are
potentially invalid.
```

`nomad job run` 명령을 check-index 옵션과 함께 사용하여 이전 plan 출력의 Job Modify Index: 54 값을 사용해서 새로운 job을 실행한다. 2개의 allocation이 created 되고 1개의 allocation이 modified 됨을 확인할 수 있다.

```sh
$ nomad job run -check-index 54 example.nomad
==> Monitoring evaluation "3e32fe8e"
    Evaluation triggered by job "example"
==> Monitoring evaluation "3e32fe8e"
    Evaluation within deployment: "1dc28f16"
    Allocation "0c253f9e" created: node "3a3dd316", group "cache"
    Allocation "1d9ce389" created: node "3a3dd316", group "cache"
    Allocation "6085301b" modified: node "eeff52e3", group "cache"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "3e32fe8e" finished with status "complete"
```
job을 중지하고 모든 re-allocation 컨테이너의 할당을 취소하려면 다음 명령을 실행한다. 
```sh
$ nomad job stop example
==> Monitoring evaluation "f6e09803"
    Evaluation triggered by job "example"

==> Monitoring evaluation "f6e09803"
    Evaluation within deployment: "1dc28f16"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "f6e09803" finished with status "complete"
```

job이 완전히 중지되었는지 확인하려면 다음을 실행한다.

```sh
$ nomad status example
ID            = example
Name          = example
Submit Date   = 2021-06-15T04:25:24Z
Type          = service
Priority      = 50
Datacenters   = dc1
Namespace     = default
Status        = dead (stopped)
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
cache       0       0         0        0       5         0

Latest Deployment
ID          = 1dc28f16
Status      = successful
Description = Deployment completed successfully

Deployed
Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
cache       3        3       3        0          2021-06-15T04:35:43Z

Allocations
ID        Node ID   Task Group  Version  Desired  Status    Created     Modified
0c253f9e  3a3dd316  cache       5        stop     complete  13m54s ago  1m17s ago
1d9ce389  3a3dd316  cache       5        stop     complete  13m54s ago  1m17s ago
6085301b  eeff52e3  cache       5        stop     complete  2h41m ago   1m17s ago
```

job의 Status 속성이 "dead(stopped)"로 표시되는지 확인할 수 있다. Allocations 섹션에서 세 allocation 모두 "complete" 상태임을 확인할 수 있다.  

