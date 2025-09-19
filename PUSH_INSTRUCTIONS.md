# Instruções para Publicar o Repositório

## 1. Criar o repositório no GitHub
- Acesse: https://github.com/netoncast
- Clique em "New repository"
- Nome: `react-native-ble-bpeople`
- Marque como **Public**
- **NÃO** inicialize com README, .gitignore ou license

## 2. Fazer o push
Execute no terminal:

```bash
cd /tmp/react-native-ble-bpeople
git push -u origin master
```

## 3. Se der erro de autenticação
Use um token do GitHub:

```bash
git remote set-url origin https://SEU_TOKEN@github.com/netoncast/react-native-ble-bpeople.git
git push -u origin master
```

## 4. Depois do push, testar no app
```bash
cd /Users/ncast/Works/SunStar/bPeople/app
yarn install
```

## O que foi incluído no fork:
- ✅ Service UUID completo no iOS (não mais truncado)
- ✅ Manufacturer Data limpo (sem bytes extras)
- ✅ Comunicação Android ↔ iOS funcionando 100%
- ✅ Nome do pacote alterado para `react-native-ble-bpeople`
