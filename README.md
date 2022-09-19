# elements-testing-dockerfile
Elements and Bitcoin for testing docker.

## build

with buildx:

```
docker buildx build .
```

with build:

```
(amd64)
docker build -f amd64.dockerfile .

(arm64)
docker build -f arm64.dockerfile .
```

### for WSL

When using buildx with WSL, please exclude the Windows environment path.
The build may fail because it reads the meta-information of the Windows environment.

## NOTE

When using with github actions, please use the root user.

```
docker login docker.pkg.github.com -u owner -p ${{ secrets.GITHUB_TOKEN }}
docker pull (image)
docker run -u root -v ${{ github.workspace }}:/github/workspace --entrypoint xxxx (image)
```
