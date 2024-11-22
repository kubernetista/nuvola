# Strange errors during docker push to Gitea Container Registry

If the image tag is:

`git.localtest.me/aruba-demo/fastapi-uv:v0.3.7-9`

The container image is accepted.
If it's instead:

`git.localtest.me/aruba-demo/fastapi-uv/fastapi-uv:v0.3.7-9`

The push fails, unless the last - is replaced with _ :

`git.localtest.me/aruba-demo/fastapi-uv/fastapi-uv:v0.3.7_9`
