# Limpeza completa do Docker

Atenção: os comandos abaixo removem dados permanentemente. Execute apenas se tiver certeza.

## Parada e remoção de containers (seguro)

Parar todos os containers em execução:

```bash
docker stop $(docker ps -q)
```

Remover todos os containers (parados ou não):

```bash
docker rm -f $(docker ps -aq)
```

Explicação: `docker ps -q` lista IDs dos containers em execução; `docker ps -aq` lista todos. O `-f` força a parada e remoção.

## Remover todas as imagens

Remover todas as imagens locais:

```bash
docker rmi -f $(docker images -aq)
```

Explicação: isso delete todas as imagens locais, forçando a remoção mesmo que estejam em uso (por isso pare/remova containers antes).

## Remover todos os volumes (dados persistentes)

Remover todos os volumes:

```bash
docker volume rm $(docker volume ls -q)
```

Ou, forçando sem erro se nenhum existir:

```bash
docker volume prune -f
```

Atenção: volumes contêm dados persistentes (bancos, arquivos). Faça backup se necessário.

## Remover todas as networks não padrão

Remover networks criadas (não remove networks padrão do Docker):

```bash
docker network rm $(docker network ls -q)
```

Se houver erro ao remover as redes padrão, remova apenas as não-default:

```bash
docker network ls --filter "driver=bridge" -q | xargs -r docker network rm
```

## One-liner “tudo” (destrutivo)

Um comando que geralmente limpa containers, imagens, volumes e networks não utilizados:

```bash
docker system prune -a --volumes -f
```

Explicação:
- `system prune` remove containers parados, networks não usadas, imagens pendentes (dangling) e cache.
- `-a` inclui imagens não utilizadas (não apenas dangling).
- `--volumes` inclui volumes.
- `-f` não pede confirmação.

## Remoção completa do runtime Docker (wipe, bem destrutivo)

Caso queira apagar tudo do Docker no host (inclui dados de daemon, imagens, volumes, configs), pare o serviço e remova diretórios — cuidado extremo:

1) Parar o daemon:

```bash
sudo systemctl stop docker
sudo systemctl stop containerd
```

2) Remover diretórios (Isto DESTRÓI todos os dados do Docker):

```bash
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

3) (Opcional) Reiniciar o serviço Docker:

```bash
sudo systemctl start containerd
sudo systemctl start docker
```

Obs: dependendo da sua distro/instalação, caminhos adicionais podem existir (ex.: /var/run/docker, /etc/docker, ~/.docker). Não execute sem ter backups.

## Se você usa docker-compose

Parar e remover serviços/volumes de um compose na pasta do projeto:

```bash
docker-compose down --rmi all --volumes --remove-orphans
```

Ou, com compose v2 (plugin):

```bash
docker compose down --rmi all --volumes --remove-orphans
```

## Scripts seguros: confirmar antes de executar

Se quiser um script que peça confirmação antes de executar a limpeza completa:

```bash
#!/usr/bin/env bash
read -p "ATENÇÃO: isso removerá containers, imagens, volumes e networks do Docker. Continuar? (s/N) " yn
if [[ $yn =~ ^[sS] ]]; then
  docker stop $(docker ps -q) || true
  docker rm -f $(docker ps -aq) || true
  docker rmi -f $(docker images -aq) || true
  docker volume rm $(docker volume ls -q) || true
  docker network rm $(docker network ls -q) || true
  docker system prune -a --volumes -f || true
  echo "Limpeza completa executada."
else
  echo "Aborted."
fi
```

Salve como `docker-wipe.sh`, torne executável (`chmod +x docker-wipe.sh`) e rode com cuidado.

## Boas práticas e segurança

- Faça backup de dados importantes (volumes, bancos).
- Pare serviços críticos antes.
- Primeiro rode comandos não destrutivos (listar: `docker ps -a`, `docker images`, `docker volume ls`).
- Se estiver em CI ou servidor remoto, confirme que não removerá algo em produção.

## Resumo (comando mais usado para “tudo”)

```bash
docker system prune -a --volumes -f
```

Se quiser que eu mova esse arquivo para outro local ou crie um script executável em `tools/`, me diga onde quer. Obrigado!