-- Script de teste para verificar as novas regras de negócio
-- Execute este script no Supabase SQL Editor após aplicar as novas funções

-- 1. Verificar se as funções foram criadas corretamente
SELECT 
    'Verificação das Funções' as teste,
    proname as nome_funcao,
    CASE 
        WHEN proname = 'contar_alocacoes_sala_dia' THEN '✅ Função auxiliar criada'
        WHEN proname = 'contar_cursos_mesmo_horario' THEN '✅ Função auxiliar criada'
        WHEN proname = 'curso_ja_alocado_horario' THEN '✅ Função auxiliar criada'
        WHEN proname = 'definir_horarios_agendamento' THEN '✅ Função principal atualizada'
        ELSE '❓ Função não esperada'
    END as status
FROM pg_proc 
WHERE proname IN ('contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario', 'definir_horarios_agendamento')
ORDER BY proname;

-- 2. Verificar se o trigger está usando a nova função
SELECT 
    'Verificação do Trigger' as teste,
    trigger_name,
    action_statement,
    CASE 
        WHEN action_statement LIKE '%definir_horarios_agendamento%' THEN '✅ Usando nova função'
        ELSE '❌ Usando função antiga'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND trigger_name LIKE '%validar%'
ORDER BY trigger_name;

-- 3. Teste das novas regras - Simular cenários
-- NOTA: Estes são testes conceituais, não inserções reais

-- Teste 1: Verificar se a função conta corretamente alocações por dia
SELECT 
    'Teste 1: Contagem de Alocações' as teste,
    'Função contar_alocacoes_sala_dia deve retornar número correto' as descricao,
    'Execute manualmente: SELECT contar_alocacoes_sala_dia(1, CURRENT_DATE)' as comando;

-- Teste 2: Verificar se a função conta cursos no mesmo horário
SELECT 
    'Teste 2: Contagem de Cursos por Horário' as teste,
    'Função contar_cursos_mesmo_horario deve retornar número correto' as descricao,
    'Execute manualmente: SELECT contar_cursos_mesmo_horario(1, CURRENT_DATE, 1, ''Primeira Aula'')' as comando;

-- Teste 3: Verificar se a função detecta curso duplicado
SELECT 
    'Teste 3: Detecção de Curso Duplicado' as teste,
    'Função curso_ja_alocado_horario deve retornar true/false' as descricao,
    'Execute manualmente: SELECT curso_ja_alocado_horario(1, CURRENT_DATE, 1, ''Primeira Aula'', 1)' as comando;

-- 4. Instruções para testes manuais
SELECT 
    'TESTES MANUAIS NECESSÁRIOS' as categoria,
    '1. Tente criar uma aula em uma sala que já tem 12 alocações no dia' as teste_1,
    '2. Tente criar uma segunda aula no mesmo horário (deve permitir)' as teste_2,
    '3. Tente criar uma terceira aula no mesmo horário (deve bloquear)' as teste_3,
    '4. Tente criar uma prova no mesmo horário de uma aula (deve bloquear)' as teste_4,
    '5. Tente criar um evento no mesmo horário (deve permitir)' as teste_5;

-- 5. Verificar estrutura da tabela agendamento
SELECT 
    'Estrutura da Tabela' as categoria,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'agendamento'
ORDER BY ordinal_position;

-- 6. Verificar se há dados de teste
SELECT 
    'Dados de Teste' as categoria,
    COUNT(*) as total_agendamentos,
    COUNT(DISTINCT sala_id) as salas_utilizadas,
    COUNT(DISTINCT curso_id) as cursos_utilizados,
    COUNT(DISTINCT dia) as dias_com_agendamento
FROM agendamento;

-- 7. Verificar distribuição por tipo de agendamento
SELECT 
    'Distribuição por Tipo' as categoria,
    tipo_agendamento,
    COUNT(*) as quantidade,
    CASE 
        WHEN tipo_agendamento = 'A' THEN 'Aula'
        WHEN tipo_agendamento = 'M' THEN 'Prova'
        WHEN tipo_agendamento = 'E' THEN 'Evento'
        ELSE 'Desconhecido'
    END as tipo_descricao
FROM agendamento 
GROUP BY tipo_agendamento
ORDER BY tipo_agendamento;

-- 8. Verificar alocações por sala por dia (top 10)
SELECT 
    'Alocações por Sala/Dia (Top 10)' as categoria,
    sala_id,
    dia,
    COUNT(*) as total_alocacoes,
    CASE 
        WHEN COUNT(*) >= 12 THEN '⚠️ LIMITE ATINGIDO'
        WHEN COUNT(*) >= 10 THEN '⚠️ PRÓXIMO DO LIMITE'
        ELSE '✅ OK'
    END as status
FROM agendamento 
GROUP BY sala_id, dia
ORDER BY COUNT(*) DESC
LIMIT 10;

-- 9. Verificar cursos no mesmo horário
SELECT 
    'Cursos no Mesmo Horário' as categoria,
    sala_id,
    dia,
    periodo,
    aula_periodo,
    COUNT(DISTINCT curso_id) as cursos_diferentes,
    CASE 
        WHEN COUNT(DISTINCT curso_id) >= 2 THEN '⚠️ 2 CURSOS (LIMITE)'
        WHEN COUNT(DISTINCT curso_id) = 1 THEN '✅ 1 CURSO'
        ELSE '❓ SEM CURSOS'
    END as status
FROM agendamento 
GROUP BY sala_id, dia, periodo, aula_periodo
HAVING COUNT(DISTINCT curso_id) >= 1
ORDER BY COUNT(DISTINCT curso_id) DESC, dia DESC
LIMIT 10;

-- 10. Resumo das novas regras implementadas
SELECT 
    'RESUMO DAS NOVAS REGRAS' as categoria,
    '✅ Limite total: 12 alocações por sala por dia' as regra_1,
    '✅ Aulas: máximo 2 cursos no mesmo horário' as regra_2,
    '✅ Provas: mantém regra antiga (1 curso por horário)' as regra_3,
    '✅ Eventos: permite múltiplos cursos sem restrição' as regra_4,
    '✅ Funções auxiliares criadas para validação' as regra_5; 