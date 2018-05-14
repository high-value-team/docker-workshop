# configure drone ci

visit http://drone.hvt.zone/account/token to get DRONE_TOKEN

prepare environment Variables

```
cp run.example run.sh
```

build and execute scripts
```
docker build --tag configure-drone-ci .
docker run -rm configure-drone-ci
```
