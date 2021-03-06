# 1. Nomad Basic

## Binary Download

[https://www.nomadproject.io/downloads](https://www.nomadproject.io/downloads) 

## **Nomad CLI**

### Nomad CLI Version

`nomad version`

### 모든 Nomad CLI 명령 목록

`nomad`

### 도움말 : `-h`, `-help`, `--help`

`nomad job run -h`

## Run Nomad Agent (Dev Mode)

Nomad는 클러스터의 모든 시스템에 대해 에이전트를 사용한다. 에이전트는 서버 또는 클라이언트 모드에서 실행할 수 있다. 

개발(Dev) 모드에서 실행한다. 개발 모드는 클라이언트와 서버 역할을 모두 수행하는 에이전트를 빠르게 시작하는 데 사용된다. 

`nomad agent -dev -bind=0.0.0.0 &`

위의 명령을 실행하면 로그 데이터가 출력되고 백그라운드에서 실행된다. Nomad UI는 http://<ip>:4646 으로 접근이 가능하다.  

에이전트를 실행 중인 Nomad 노드의 상태를 살펴보자.

`nomad node status`

```bash
$ nomad node status
ID        DC   Name               Class   Drain  Eligibility  Status
0ef7882b  dc1  jinwoong-work-MBP  <none>  false  eligible     ready
```

ID, 데이터 센터(DC), Name, Class, Drain, Eligibility 및 Status를 포함한 노드에 대한 정보가 출력된다.

로컬 Nomad 클러스터의 서버 목록을 가져와 에이전트가 서버로 실행되고 있는지 확인한다.

`nomad server members`

```bash
nomad server members
Name                      Address        Port  Status  Leader  Protocol  Build  Datacenter  Region
jinwoong-work-MBP.global  192.168.15.86  4648  alive   true    2         1.0.5  dc1         global
```

nomad-server 노드가 클러스터의 멤버이며 실제로 클러스터의 리더이며 alive 상태임을 알 수 있다.

## **Run Your First Nomad Job**

아래 Nomad Job Specification 파일을 사용하여 Nomad Job을 실행한다.

이미지, 리소스 및 헬스 체크를 포함하여 작업의 세부 정보를 작성한다. 

먼저 작업 사양 파일 `redis.nomad` 를 확인한다.

```jsx
cat redis.nomad

job "redis" {
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

job을 실행한다.

```jsx
nomad job run redis.nomad
==> Monitoring evaluation "e2f78f37"
    Evaluation triggered by job "redis"
    Evaluation within deployment: "8c4262b2"
    Allocation "cb432d76" created: node "766d804f", group "cache"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "e2f78f37" finished with status "complete"
```

그 결과, evaluation 의 라이프사이클이 표시되고, 노드에 allocation이 생성되었으며, evaluation 상태가 "pending"에서 "complete"로 변경되었음을 확인할 수 있다.

다음으로 Redis 작업의 상태를 확인한다. 

```jsx
nomad status
ID     Type     Priority  Status   Submit Date
redis  service  50        running  2021-06-14T03:24:30Z
```

이 명령은 Redis job의 Status "running" 및 submit date를 반환한다.

job을 중지한다.

```jsx
nomad job stop redis
==> Monitoring evaluation "bca1769d"
    Evaluation triggered by job "redis"
    Evaluation within deployment: "8c4262b2"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "bca1769d" finished with status "complete"
```

job이 중지되면 job evalution 진행상태가 다시 표시된다. 

다시한번 job의 status를 다시 보고 job이 중지되었음을 확인한다.

`nomad status`

```jsx
nomad status
ID     Type     Priority  Status          Submit Date
redis  service  50        dead (stopped)  2021-06-14T03:24:30Z
```

The status is now "dead (stopped)".

Next, we'll run through a similar process utilizing the Nomad User Interface (UI). Click on the "Nomad UI" tab. (If it looks scrunched up, either make your browser window wider or click the rectangular icon above the "Nomad UI" tab to temporarily hide the assignment. Clicking that icon again will unhide the assignment.)

Within the Nomad UI, select the "redis" job. On the "Job Overview" tab, click the red "Start" button. Nomad will ask for confirmation; confirm by clicking the "Yes, Start" button.

In the UI, observe that the job is started and that there is one healthy allocation as desired.

Return to the Nomad CLI tab, and check on the job status:

이제 상태가 "dead(stopped)" 이다.

그런 다음 UI(Nomad User Interface)를 사용하여 유사한 프로세스를 실행한다. 로컬에서 실행한 경우 [http://localhost:4646](http://localhost:4646)  으로 접근할 수 있다. 

Nomad UI에서 "redis" 작업을 선택한다. Jobs redis의 Overview 메뉴에서 빨간색 `Start` 단추를 클릭한다. 

UI에서 job이 시작되고 원하는 대로 정상적인 allocation이 있는지 확인 한다. 

![Untitled.png](/01/assets/Untitled.png)

Nomad CLI 탭으로 돌아가 작업 상태를 확인한다. CLI에서 작업 상태가 "running"이라고 표시하는지 확인한다.

`nomad status`

```bash
nomad status
ID     Type     Priority  Status   Submit Date
redis  service  50        running  2021-06-14T14:17:21+09:00
```

Nomad UI에서 `Stop` 버튼을 클릭하여 작업을 중지한다. 

Nomad UI에서 작업이 중지되었는지 확인하면 실행 중인 job의 개수가 0임을 확인할수 있다. 

Noamad CLI 탭으로 돌아가 "dead(stopped)" 상태가 CLI에도 반영되는지 확인한다.

`nomad status`

```bash
nomad status
ID     Type     Priority  Status          Submit Date
redis  service  50        dead (stopped)  2021-06-14T14:17:21+09:00
```

## Nomad HTTP API

먼저 redis.nomad 파일에서 HTTP API로 전송할 수 있는 작업의 JSON을 생성한다. 

`nomad job run -output redis.nomad > payload.json`

Nomad 서버의 HTTP API에 대해 다음 curl 명령을 실행하여 payload.json 파일에서 job을 생성한다. 시각적으로 확인하기 위해 `jq` 를 사용한다 

`curl --data @payload.json http://localhost:4646/v1/jobs | jq`

```bash
curl --data @payload.json http://localhost:4646/v1/jobs | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3884  100   154  100  3730  77000  1821k --:--:-- --:--:-- --:--:-- 1896k
{
  "EvalID": "f5f03218-27b8-534c-aff2-bbcc599f891d",
  "EvalCreateIndex": 141,
  "JobModifyIndex": 141,
  "Warnings": "",
  "Index": 141,
  "LastContact": 0,
  "KnownLeader": false
}
```

반환되는 JSON 데이터에는 job 인덱스, evaluation ID 및 기타 정보가 포함된다.

Nomad의 HTTP API를 사용하여 작업을 생성하는 방법에 대한 자세한 내용은 [https://www.nomadproject.io/api/jobs.html#create-job](https://www.nomadproject.io/api/jobs.html#create-job)를 참조한다.  

job이 실행되면 Nomad의 HTTP API를 사용하여 job 상태를 쿼리할 수 있다.

`curl http://localhost:4646/v1/job/redis/summary | jq`

```bash
curl http://localhost:4646/v1/job/redis/summary | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   211  100   211    0     0   103k      0 --:--:-- --:--:-- --:--:--  103k
{
  "JobID": "redis",
  "Namespace": "default",
  "Summary": {
    "cache": {
      "Queued": 0,
      "Complete": 2,
      "Failed": 0,
      "Running": 1,
      "Starting": 0,
      "Lost": 0
    }
  },
  "Children": {
    "Pending": 0,
    "Running": 0,
    "Dead": 0
  },
  "CreateIndex": 96,
  "ModifyIndex": 145
}
```

JSON 응답에는 job ID("redis")와 Failed, Starting, Running등의 allocation 에 대한 카운트가 포함된다. 

API를 사용한 작업 쿼리에 대한 자세한 내용은 [https://www.nomadproject.io/api/jobs.html#read-job-summary](https://www.nomadproject.io/api/jobs.html#read-job-summary)을 참조한다. 

마지막으로 HTTP API를 사용하여 job을 중지한다.

`curl --request DELETE http://localhost:4646/v1/job/redis | jq`

```bash
curl --request DELETE http://localhost:4646/v1/job/redis | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   178  100   178    0     0  35600      0 --:--:-- --:--:-- --:--:-- 35600
{
  "EvalID": "edf39d4c-8de8-4db0-f4d0-e19ba1fe5fe2",
  "EvalCreateIndex": 154,
  "JobModifyIndex": 154,
  "VolumeEvalID": "",
  "VolumeEvalIndex": 0,
  "Index": 154,
  "LastContact": 0,
  "KnownLeader": false
}
```

반환되는 JSON 데이터에는 job 인덱스, evaluation ID 및 기타 정보가 포함된다.

API를 사용하여 작업을 중지하는 방법에 대한 자세한 내용은 [https://www.nomadproject.io/api/jobs.html#stop-a-job](https://www.nomadproject.io/api/jobs.html#stop-a-job)을 참조한다. 

작업이 올바르게 종료되었는지 확인하려면 작업 요약 API를 다시 쿼리합니다.

`curl http://localhost:4646/v1/job/redis/summary | jq`

```bash
curl http://localhost:4646/v1/job/redis/summary | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   211  100   211    0     0   103k      0 --:--:-- --:--:-- --:--:--  103k
{
  "JobID": "redis",
  "Namespace": "default",
  "Summary": {
    "cache": {
      "Queued": 0,
      "Complete": 3,
      "Failed": 0,
      "Running": 0,
      "Starting": 0,
      "Lost": 0
    }
  },
  "Children": {
    "Pending": 0,
    "Running": 0,
    "Dead": 0
  },
  "CreateIndex": 96,
  "ModifyIndex": 158
}
```

JSON 응답은 현재 실행 중인 allocation이 없으며 전체 allocation 수가 1 증가했음을 보여준다. 

`Summary.cache.Completet: 3`