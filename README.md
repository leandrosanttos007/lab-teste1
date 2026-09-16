# lab-teste1

Laboratório de CI/CD com GitOps: um site estático simples, empacotado em imagem Docker,
com pipeline que publica a imagem e atualiza automaticamente o manifesto Kubernetes em um
repositório GitOps separado.

## Arquitetura

```
push na main
     │
     ▼
GitHub Actions (.github/workflows/ci.yml)
     │
     ├─ 1. build da imagem (nginx:1.27-alpine + src/index.html)
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

- **Este repositório (`lab-teste1`)** contém apenas a aplicação (o site) e o Dockerfile.
- **O repositório `lab-teste1-gitops`** contém os manifestos Kubernetes (fonte da verdade do
  estado desejado do cluster). O pipeline nunca aplica no cluster diretamente — apenas
  atualiza o manifesto, e uma ferramenta de GitOps (ArgoCD/Flux) sincroniza o cluster a
  partir dele.

## Estrutura

```
lab-teste1/
├── src/index.html            # aplicação (site estático)
├── Dockerfile                # imagem nginx servindo src/
├── .dockerignore
└── .github/workflows/ci.yml  # pipeline: build → push → atualiza GitOps
```

## Rodar localmente

```bash
docker build -t lab-teste1:local .
docker run --rm -p 8080:80 lab-teste1:local
curl http://localhost:8080
```

## Pipeline (CI)

Disparado em todo push na `main`:

1. Build da imagem com Buildx (cache via GitHub Actions).
2. Push para o Docker Hub com duas tags: o SHA do commit (rastreabilidade) e `latest`.
3. Checkout do repositório `lab-teste1-gitops` e atualização da imagem em
   `k8s/deployment.yaml`, com commit apenas se houve mudança real (evita falha por
   "nothing to commit") e `pull --rebase` antes do push (evita conflito em execuções
   concorrentes).

### Secrets necessários no repositório

| Secret | Uso |
|---|---|
| `DOCKER_USER` / `DOCKER_PASS` | login no Docker Hub |
| `GIT_TOKEN` | Personal Access Token com permissão de escrita no repo `lab-teste1-gitops` |
