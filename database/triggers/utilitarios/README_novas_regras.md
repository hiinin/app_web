# Novas Regras de Negócio para Aulas

## Resumo das Mudanças

Este documento descreve as novas regras de negócio implementadas para o sistema de ensalamento, especificamente para **aulas**.

## Regras Anteriores

- **Limite por sala por dia**: 6 agendamentos
- **Limite por horário**: 1 curso por horário
- **Compartilhamento**: Não permitido

## Novas Regras Implementadas

### 1. Limite por Período
- **Nova regra**: Cada sala pode ter até **4 agendamentos por período** (matutino, vespertino, noturno)
- **Distribuição**: 2 aulas por horário × 2 horários = 4 aulas por período
- **Aplicação**: Aplicável a todos os tipos de agendamento (aulas, provas, eventos)

### 2. Compartilhamento de Horário para Aulas
- **Nova regra**: Em um mesmo horário, **duas turmas de cursos diferentes podem compartilhar a mesma sala**
- **Limite**: Máximo de **2 cursos diferentes** no mesmo horário
- **Aplicação**: Apenas para aulas (`tipo_agendamento = 'A'`)

### 3. Regras para Provas e Eventos
- **Provas**: Mantêm as regras antigas (1 por horário, limite de 6 por dia)
- **Eventos**: Mantêm as regras antigas (1 por horário, limite de 6 por dia)

## Implementação Técnica

### Backend (Banco de Dados)

#### 1. Nova Função de Validação
```sql
CREATE OR REPLACE FUNCTION validar_agendamento_aula_nova_regra()
RETURNS TRIGGER AS $$
```

**Validações implementadas:**
- Limite de 12 agendamentos por sala por dia
- Limite de 2 aulas no mesmo horário
- Verificação de cursos diferentes no mesmo horário
- Aplicável apenas para aulas (`tipo_agendamento = 'A'`)

#### 2. Trigger de Validação
```sql
CREATE TRIGGER trigger_validar_aula_nova_regra
    BEFORE INSERT OR UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION validar_agendamento_aula_nova_regra();
```

### Frontend (Flutter)

#### 1. Validação de Limite por Período
```dart
// Antes: if (agendamentosSala.length >= 6)
if (agendamentosSalaPeriodo.length >= 4) {
  // Nova mensagem de erro por período
}
```

#### 2. Validação de Compartilhamento de Horário
```dart
// Nova lógica para verificar até 2 aulas no mesmo horário
if (aulasMesmoHorario.length >= 2) {
  // Bloquear criação de terceira aula
}

// Verificar se o curso já está agendado
if (cursoJaAgendado) {
  // Bloquear criação de aula duplicada
}
```

## Arquivos Modificados

### Backend
1. `database/triggers/utilitarios/nova_regra_negocio_aulas.sql`
   - Implementação da nova função de validação
   - Criação do trigger

2. `database/triggers/utilitarios/teste_novas_regras_aulas.sql`
   - Scripts de teste para verificar as novas regras

### Frontend
1. `lib/pages/criarlocacao_page.dart`
   - Atualização do limite de 6 para 12 agendamentos por dia
   - Implementação da lógica de compartilhamento de horário
   - Validação de cursos diferentes no mesmo horário

## Casos de Uso

### Cenário 1: Aulas Compartilhadas
```
Horário: 08:00 - 09:40 (Primeira Aula)
Sala: 101
- Curso A: Matemática
- Curso B: Física
✅ Permitido (2 cursos diferentes)
```

### Cenário 2: Limite de Aulas
```
Horário: 08:00 - 09:40 (Primeira Aula)
Sala: 101
- Curso A: Matemática
- Curso B: Física
- Curso C: Química
❌ Bloqueado (máximo 2 cursos)
```

### Cenário 3: Curso Duplicado
```
Horário: 08:00 - 09:40 (Primeira Aula)
Sala: 101
- Curso A: Matemática
- Curso A: Matemática (tentativa)
❌ Bloqueado (curso já agendado)
```

### Cenário 4: Limite por Período
```
Sala: 101
Dia: 2024-01-15
Período: Matutino
- 4 agendamentos já existem no período
- Tentativa de criar 5º agendamento no período
❌ Bloqueado (limite de 4 por período)
```

## Testes

### Scripts de Teste Disponíveis
1. `database/triggers/utilitarios/teste_novas_regras_aulas.sql`
   - Testes automatizados das novas regras
   - Verificação de casos de sucesso e falha

### Cenários Testados
1. ✅ Criar primeira aula
2. ✅ Criar segunda aula no mesmo horário (curso diferente)
3. ❌ Tentar criar terceira aula no mesmo horário
4. ❌ Tentar criar aula com curso já agendado
5. ✅ Criar aula em horário diferente
6. ✅ Criar terceira aula no segundo horário
7. ✅ Criar quarta aula no segundo horário
8. ❌ Tentar criar quinta aula no período (limite de 4 por período)

## Compatibilidade

### Regras Mantidas
- **Provas**: Mantêm limite de 1 por horário e 6 por dia
- **Eventos**: Mantêm limite de 1 por horário e 6 por dia
- **Validações básicas**: Existência de sala, curso, matéria, professor
- **Datas passadas**: Não permitidas

### Regras Alteradas
- **Aulas**: Novo limite de 2 por horário e 4 por período
- **Compartilhamento**: Permitido apenas para aulas
- **Limite por período**: 4 agendamentos por período (matutino, vespertino, noturno)

## Monitoramento

### Métricas Importantes
1. **Taxa de sucesso**: Agendamentos criados vs tentativas
2. **Utilização de salas**: Percentual de ocupação por sala
3. **Conflitos**: Tentativas de agendamento bloqueadas

### Logs de Validação
- Todas as validações são registradas no histórico
- Mensagens de erro específicas para cada tipo de conflito
- Rastreamento de tentativas de agendamento

## Próximos Passos

### Possíveis Melhorias
1. **Interface visual**: Indicar salas com alta ocupação
2. **Sugestões**: Recomendar horários alternativos
3. **Relatórios**: Estatísticas de utilização de salas
4. **Notificações**: Alertas para conflitos de horário

### Considerações
1. **Performance**: Monitorar impacto das novas validações
2. **Usabilidade**: Feedback claro sobre regras de negócio
3. **Flexibilidade**: Possibilidade de ajustar limites por configuração 