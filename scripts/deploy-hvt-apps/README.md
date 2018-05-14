# deploy rancher stacks

prepare environment Variables

```
cp run.example run.sh
```

build and execute scripts
```
docker build --tag deploy-hvt-apps .
docker run -rm deploy-hvt-apps
```
