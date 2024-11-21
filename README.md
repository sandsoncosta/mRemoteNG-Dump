# mRemoteNG-Dump

O Multi-Remote Next Generation Connection Manager (mRemoteNG) é um software gratuito que permite aos usuários armazenar e gerenciar configurações de conexão multi-protocolo para se conectar remotamente a sistemas.

Vulnerabilidade no mRemoteNG: Gerenciamento de Configurações Criptografadas
Identificamos uma vulnerabilidade no mRemoteNG, um software usado para gerenciar conexões remotas multi-protocolo. A falha está relacionada à manipulação de arquivos de configuração criptografados (confCons.xml), permitindo que um atacante obtenha dados sensíveis como senhas.

**Descrição do Problema**
Comportamento Vulnerável: O programa converte automaticamente a criptografia de arquivos para o padrão AES+GCM ao ser transferido para outra máquina, mesmo que o usuário tenha configurado outro algoritmo/modo (ex.: AES+EAX).
Impacto: Um atacante com acesso ao arquivo pode utilizar scripts para quebrar a criptografia e obter credenciais, comprometendo a segurança de sistemas e dados sensíveis.
Recomendações de Correção
Manutenção do padrão de criptografia: Preservar as configurações de criptografia definidas pelo usuário durante transferências de arquivos.
Fortalecimento da segurança: Implementar chaves únicas por arquivo e validação de integridade (ex.: hash SHA-256).
Desativação de conversões automáticas: Remover a funcionalidade de alteração automática do método de criptografia.
Senha master obrigatória: Exigir senha master para proteger os arquivos de configuração contra acessos não autorizados.
Essa vulnerabilidade destaca a necessidade de melhorias urgentes no mRemoteNG para garantir maior proteção de dados e mitigar riscos de ataques.