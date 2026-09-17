# lab-teste1

Laboratório de CI/CD com GitOps: uma aplicação Python (Flask), empacotada em imagem Docker,
com pipeline que publica a imagem e atualiza automaticamente o manifesto Kubernetes em um
repositório GitOps separado.

## Arquitetura

```
push na main
     │
     ▼
GitHub Actions (.github/workflows/ci.yml)
     │
     ├─ 1. build da imagem (python:3.12-slim + Flask/gunicorn), com APP_VERSION=<sha>
     ├─ 2. push para o Docker Hub (leohurin/lab-teste1:<sha> e :latest)
     └─ 3. checkout do repo GitOps (lab-teste1-gitops)
             └─ atualiza k8s/deployment.yaml com a nova tag e faz commit/push
                     │
                     ▼
        ArgoCD/Flux detecta a mudança no repo GitOps
                     │
                     ▼
              aplica no cluster Kubernetes
```

- **Este repositório (`lab-teste1`)** contém apenas a aplicação e o Dockerfile.
- **O repositório `lab-teste1-gitops`** contém os manifestos Kubernetes (fonte da verdade do
  estado desejado do cluster). O pipeline nunca aplica no cluster diretamente — apenas
  atualiza o manifesto, e uma ferramenta de GitOps (ArgoCD/Flux) sincroniza o cluster a
  partir dele.

## Aplicação

Servidor Flask servido em produção via `gunicorn`, na porta `8080`, rodando como usuário
não-root. Endpoints:

| Rota | Descrição |
|---|---|
| `GET /` | página HTML com nome do app, versão (SHA do build) e horário UTC atual |
| `GET /health` | `{"status": "ok"}` — usado pelo `HEALTHCHECK` do Docker e pelas probes do Kubernetes |
| `GET /api/info` | mesmas informações da página inicial, em JSON |

## Estrutura

```
lab-teste1/
├── src/
│   ├── app.py                    # aplicação Flask
│   ├── templates/index.html      # página renderizada dinamicamente
│   └── requirements.txt
├── Dockerfile                    # python:3.12-slim, usuário não-root, gunicorn
├── .dockerignore
└── .github/workflows/ci.yml      # pipeline: build → push → atualiza GitOps
```

## Rodar localmente

```bash
docker build -t lab-teste1:local .
docker run --rm -p 8080:8080 lab-teste1:local
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/api/info
```

## Pipeline (CI)

Disparado em todo push na `main`:

1. Build da imagem localmente no runner (`load: true`, sem push), com cache via GitHub Actions
   e `APP_VERSION=<sha>` como build-arg — a aplicação exibe essa versão em `/` e `/api/info`.
2. **Smoke test:** sobe um container a partir dessa imagem e faz `curl /health` (com retries)
   antes de publicar. Se o container não responder, o pipeline falha aqui e a imagem **nunca**
   chega ao Docker Hub.
3. Push para o Docker Hub com duas tags: o SHA do commit (rastreabilidade) e `latest`. Reaproveita
   o cache do passo 1, então é rápido.
4. Checkout do repositório `lab-teste1-gitops` e atualização da imagem em
   `k8s/deployment.yaml`, com commit apenas se houve mudança real (evita falha por
   "nothing to commit") e `pull --rebase` antes do push (evita conflito em execuções
   concorrentes).

### Secrets necessários no repositório

| Secret | Uso |
|---|---|
| `DOCKER_USER` / `DOCKER_PASS` | login no Docker Hub (usar Access Token, não a senha da conta) |
| `GIT_TOKEN` | Personal Access Token (escopo `repo`) com permissão de escrita no repo `lab-teste1-gitops` |
