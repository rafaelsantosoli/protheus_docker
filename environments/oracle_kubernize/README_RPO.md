# Informações sobre RPO Customizado - Oracle Kubernize

## ⚠️ Problema Identificado

O arquivo RPO customizado `tttm120.rpo` **não é compatível** com a versão **12.1.2510** do Protheus AppServer.

### Erro Observado
```
[WARN ][SERVER] [Thread 171] [14/01/2026 11:32:44] Thread finished (rafae, RAFAEL) 
Invalid function call : sigamdi
```

O AppServer tenta executar a função `sigamdi` automaticamente (provavelmente a partir de inicialização automática de usuário ou job), mas essa função **não existe no RPO customizado**.

## 📋 Possíveis Causas

1. **Versão incompatível do RPO**: O RPO foi compilado para Protheus 12.0.x, não 12.1.2510
2. **Funções faltando**: O RPO não inclui todos os módulos/funções necessários
3. **Incompatibilidade de estrutura**: Mudanças na estrutura de dados entre versões

## ✅ Solução Atual

Atualmente, o ambiente **funciona perfeitamente** sem o RPO customizado, usando apenas:
- `/opt/totvs/appserver/tlpp.rpo` (core do Protheus)
- `/opt/totvs/appserver/custom.rpo` (customizações padrão)

## 📝 Como Usar o RPO Customizado

### ⚠️ Importante: O RPO Precisa Ser Recompilado

O arquivo RPO customizado atual **NÃO FUNCIONA** com Protheus 12.1.2510 porque:
- Está compilado para versão anterior (provavelmente 12.0.x)
- **Falta a função `sigamdi`** que é chamada automaticamente
- Possui incompatibilidades estruturais

**Não é possível usar este RPO sem recompilação.**

### ✅ Solução: Recompilar o RPO

1. **Abra o Protheus Developer Studio (TDSv12)** ou superior
2. **Abra o projeto do RPO customizado**
3. **Verifique todos os programas/funções**:
   - Procure por `sigamdi` e qualquer função faltante
   - Atualize imports e referências
4. **Compile para Protheus 12.1.2510**
5. **Substitua** o arquivo: `data/totvs/protheus/apo/tttm120.rpo`
6. **Copie para o container**:
   ```bash
   docker cp data/totvs/protheus/apo/tttm120.rpo oracle_kubernize-protheus:/opt/totvs/protheus/volume/current/apo/
   docker compose restart protheus
   ```

## 🔧 Remover RPO (Restaurar Funcionamento)

Se o Protheus ficar em restart loop devido ao RPO:

```bash
cd environments/oracle_kubernize

# Parar containers
docker compose down -v

# Reiniciar (sem RPO)
docker compose up -d
```

## 📊 Status Atual do Ambiente

```
✅ Oracle 19c - Healthy
✅ DBAccess 12.1.2510 - Healthy  
✅ Protheus AppServer 12.1.2510 - Healthy (SEM RPO customizado)
✅ Conexão com banco de dados Oracle - Funcionando
✅ Porta 1234 (SmartClient) - Disponível
✅ Porta 8086 (WebApp) - Disponível
```

## 🎯 Próximos Passos Recomendados

1. **Validar RPO**: Confirm que o arquivo RPO é para versão 12.1.2510
2. **Teste de Compatibilidade**: Compilar e testar em ambiente de desenvolvimento
3. **Verificar Dependências**: Certificar-se de que o RPO não depende de customizações externas que não existem

---

**Data**: 14 de janeiro de 2026  
**Versão**: 1.0
