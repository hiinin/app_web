# Triggers do Banco de Dados

Esta pasta contém todos os triggers e funções SQL organizados por categoria para facilitar a manutenção e localização.

## Estrutura de Pastas

### 📁 historico/
Triggers e funções relacionados ao histórico de ações do sistema:
- `triggers_historico_acoes.sql` - Trigger principal para registrar histórico
- `verificar_triggers_historico*.sql` - Scripts para verificar triggers de histórico
- `recriar_triggers_historico.sql` - Recriar triggers de histórico
- `reabilitar_triggers_historico.sql` - Reabilitar triggers de histórico
- `limpar_historico*.sql` - Scripts para limpeza de dados de histórico

### 📁 agendamento/
Triggers e funções relacionados ao sistema de agendamento:
- `trigger_horarios_automaticos.sql` - Trigger para horários automáticos
- `configuracao_*_agendamento_multiplo.sql` - Configurações para agendamentos múltiplos
- `reabilitar_triggers_agendamento.sql` - Reabilitar triggers de agendamento
- `desabilitar_triggers_agendamento.sql` - Desabilitar triggers de agendamento

### 📁 professores/
Triggers e funções relacionados aos professores:
- `atualizar_professores*.sql` - Scripts para atualização de dados de professores
- `verificar_relacionamento_professor_materia.sql` - Verificar relacionamentos

### 📁 utilitarios/
Scripts utilitários e de manutenção:
- `verificar_*.sql` - Scripts para verificar estruturas e funções
- `corrigir_*.sql` - Scripts para correção de problemas
- `recriar_triggers_simples.sql` - Recriar triggers básicos
- `disable_triggers_functions.sql` - Desabilitar triggers e funções
- `remove_*.sql` - Scripts para remoção de dados duplicados

## Como Usar

1. **Para histórico**: Execute os scripts da pasta `historico/` para gerenciar o sistema de histórico
2. **Para agendamento**: Use os scripts da pasta `agendamento/` para configurar agendamentos
3. **Para professores**: Execute scripts da pasta `professores/` para atualizar dados de professores
4. **Para manutenção**: Use os scripts da pasta `utilitarios/` para verificações e correções

## Ordem de Execução Recomendada

1. Primeiro execute os scripts de `utilitarios/` para verificar a estrutura
2. Em seguida, execute os scripts específicos da categoria desejada
3. Use os scripts de reabilitação se necessário

## Notas Importantes

- Sempre faça backup antes de executar scripts de modificação
- Execute os scripts em ambiente de desenvolvimento primeiro
- Verifique as dependências entre os scripts antes da execução 