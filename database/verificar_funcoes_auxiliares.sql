-- Script para verificar se as funções auxiliares estão funcionando corretamente
-- Execute este script no Supabase SQL Editor

-- 1. Verificar se todas as funções auxiliares existem
SELECT 
    'Verificação das Funções Auxiliares' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN proname = 'contar_alocacoes_sala_dia' THEN '✅ NECESSÁRIA - Conta alocações por dia'
        WHEN proname = 'contar_cursos_mesmo_horario' THEN '✅ NECESSÁRIA - Conta cursos no mesmo horário'
        WHEN proname = 'curso_ja_alocado_horario' THEN '✅ NECESSÁRIA - Verifica curso duplicado'
        WHEN proname = 'definir_horarios_agendamento' THEN '✅ PRINCIPAL - Função principal'
        ELSE '❓ Função não esperada'
    END as status
FROM pg_proc 
WHERE proname IN ('contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario', 'definir_horarios_agendamento')
ORDER BY proname;

-- 2. Testar as funções auxiliares com dados reais (se existirem)
-- Teste da função contar_alocacoes_sala_dia
SELECT 
    'Teste: contar_alocacoes_sala_dia' as teste,
    sala_id,
    dia,
    COUNT(*) as alocacoes_existentes,
    contar_alocacoes_sala_dia(sala_id, dia) as resultado_funcao,
    CASE 
        WHEN COUNT(*) = contar_alocacoes_sala_dia(sala_id, dia) THEN '✅ CORRETO'
        ELSE '❌ PROBLEMA'
    END as status
FROM agendamento 
GROUP BY sala_id, dia
ORDER BY COUNT(*) DESC
LIMIT 5;

-- 3. Testar a função contar_cursos_mesmo_horario
SELECT 
    'Teste: contar_cursos_mesmo_horario' as teste,
    sala_id,
    dia,
    periodo,
    aula_periodo,
    COUNT(DISTINCT curso_id) as cursos_existentes,
    contar_cursos_mesmo_horario(sala_id, dia, periodo, aula_periodo) as resultado_funcao,
    CASE 
        WHEN COUNT(DISTINCT curso_id) = contar_cursos_mesmo_horario(sala_id, dia, periodo, aula_periodo) THEN '✅ CORRETO'
        ELSE '❌ PROBLEMA'
    END as status
FROM agendamento 
GROUP BY sala_id, dia, periodo, aula_periodo
HAVING COUNT(DISTINCT curso_id) > 0
ORDER BY COUNT(DISTINCT curso_id) DESC
LIMIT 5;

-- 4. Testar a função curso_ja_alocado_horario
SELECT 
    'Teste: curso_ja_alocado_horario' as teste,
    sala_id,
    dia,
    periodo,
    aula_periodo,
    curso_id,
    curso_ja_alocado_horario(sala_id, dia, periodo, aula_periodo, curso_id) as resultado_funcao,
    CASE 
        WHEN curso_ja_alocado_horario(sala_id, dia, periodo, aula_periodo, curso_id) = true THEN '✅ CORRETO (curso já alocado)'
        ELSE '✅ CORRETO (curso não alocado)'
    END as status
FROM agendamento 
ORDER BY dia DESC, sala_id
LIMIT 5;

-- 5. Verificar se o trigger está configurado corretamente
SELECT 
    'Verificação do Trigger' as categoria,
    trigger_name,
    action_statement,
    CASE 
        WHEN action_statement LIKE '%definir_horarios_agendamento%' THEN '✅ CONFIGURADO CORRETAMENTE'
        ELSE '❌ PROBLEMA NA CONFIGURAÇÃO'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND trigger_name LIKE '%validar%'
ORDER BY trigger_name;

-- 6. Verificar se há dados para teste
SELECT 
    'Dados Disponíveis para Teste' as categoria,
    COUNT(*) as total_agendamentos,
    COUNT(DISTINCT sala_id) as salas_utilizadas,
    COUNT(DISTINCT curso_id) as cursos_utilizados,
    COUNT(DISTINCT dia) as dias_com_agendamento,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Há dados para teste'
        ELSE '⚠️ Sem dados para teste'
    END as status
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

-- 8. Resumo das novas regras implementadas
SELECT 
    'RESUMO DAS NOVAS REGRAS' as categoria,
    '✅ Limite total: 12 alocações por sala por dia' as regra_1,
    '✅ Aulas: máximo 2 cursos no mesmo horário' as regra_2,
    '✅ Provas: mantém regra antiga (1 curso por horário)' as regra_3,
    '✅ Eventos: permite múltiplos cursos sem restrição' as regra_4,
    '✅ Função principal: definir_horarios_agendamento' as regra_5,
    '✅ Funções auxiliares: contar_alocacoes_sala_dia, contar_cursos_mesmo_horario, curso_ja_alocado_horario' as regra_6;

-- 9. Instruções para teste manual
SELECT 
    'TESTES MANUAIS NECESSÁRIOS' as categoria,
    '1. Tente criar uma aula em uma sala com dados existentes' as teste_1,
    '2. Tente criar uma segunda aula (curso diferente) no mesmo horário' as teste_2,
    '3. Tente criar uma terceira aula no mesmo horário (deve falhar)' as teste_3,
    '4. Tente criar uma prova no mesmo horário de uma aula (deve falhar)' as teste_4,
    '5. Tente criar um evento no mesmo horário (deve permitir)' as teste_5; 