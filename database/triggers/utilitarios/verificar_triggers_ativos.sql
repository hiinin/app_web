-- Script para verificar quais triggers estão realmente ativos no Supabase
-- Execute este script no Supabase SQL Editor

-- 1. Verificar TODOS os triggers ativos na tabela agendamento
SELECT 
    'Triggers Ativos no Supabase' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 2. Verificar funções que estão sendo usadas pelos triggers
SELECT 
    'Funções dos Triggers' as info,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%definir_horarios%' THEN '🕐 Horários Automáticos'
        WHEN prosrc LIKE '%validar%' THEN '✅ Validação'
        WHEN prosrc LIKE '%conflito%' THEN '⚠️ Conflito'
        WHEN prosrc LIKE '%historico%' THEN '📝 Histórico'
        ELSE '🔧 Outro'
    END as tipo_funcao
FROM pg_proc 
WHERE proname IN (
    SELECT DISTINCT 
        SUBSTRING(action_statement FROM 'EXECUTE FUNCTION ([^(]+)')
    FROM information_schema.triggers 
    WHERE event_object_table = 'agendamento'
)
ORDER BY proname;

-- 3. Verificar se os triggers da pasta estão ativos
SELECT 
    'Triggers da Pasta vs Supabase' as info,
    'trigger_definir_horarios' as trigger_pasta,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_definir_horarios'
        ) THEN '✅ Ativo'
        ELSE '❌ Não ativo'
    END as status_supabase
UNION ALL
SELECT 
    'Triggers da Pasta vs Supabase' as info,
    'trigger_validar_aula_nova_regra' as trigger_pasta,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_validar_aula_nova_regra'
        ) THEN '✅ Ativo'
        ELSE '❌ Não ativo'
    END as status_supabase
UNION ALL
SELECT 
    'Triggers da Pasta vs Supabase' as info,
    'trigger_validar_agendamento_basico' as trigger_pasta,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_validar_agendamento_basico'
        ) THEN '✅ Ativo'
        ELSE '❌ Não ativo'
    END as status_supabase;

-- 4. Verificar status dos triggers (habilitado/desabilitado)
SELECT 
    'Status dos Triggers' as info,
    tgname as trigger_name,
    CASE 
        WHEN tgenabled = 'D' THEN '❌ Desabilitado'
        WHEN tgenabled = 'E' THEN '✅ Habilitado'
        WHEN tgenabled = 'A' THEN '🔄 Sempre'
        WHEN tgenabled = 'R' THEN '🔄 Replica'
        ELSE '❓ Desconhecido'
    END as status
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
ORDER BY tgname;

-- 5. Verificar se há triggers conflitantes
SELECT 
    'Triggers Conflitantes' as info,
    trigger_name,
    CASE 
        WHEN action_statement LIKE '%conflito%' OR action_statement LIKE '%horario%' THEN '⚠️ Possível conflito'
        WHEN action_statement LIKE '%validar%' AND action_statement NOT LIKE '%basico%' THEN '⚠️ Validação antiga'
        ELSE '✅ OK'
    END as observacao
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND (action_statement LIKE '%conflito%' 
       OR action_statement LIKE '%horario%' 
       OR (action_statement LIKE '%validar%' AND action_statement NOT LIKE '%basico%'))
ORDER BY trigger_name;

-- 6. Verificar funções que podem estar causando problemas
SELECT 
    'Funções Problemáticas' as info,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%conflito%' THEN '⚠️ Valida conflitos'
        WHEN prosrc LIKE '%horario%' AND prosrc NOT LIKE '%automaticos%' THEN '⚠️ Valida horários'
        WHEN prosrc LIKE '%validar%' AND prosrc NOT LIKE '%basico%' THEN '⚠️ Validação antiga'
        ELSE '✅ OK'
    END as observacao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
  AND (prosrc LIKE '%conflito%' 
       OR (prosrc LIKE '%horario%' AND prosrc NOT LIKE '%automaticos%')
       OR (prosrc LIKE '%validar%' AND prosrc NOT LIKE '%basico%'))
ORDER BY proname;

-- 7. Resumo dos triggers da pasta
SELECT 
    'Triggers da Pasta' as info,
    'trigger_horarios_automaticos.sql' as arquivo,
    'Define horários automaticamente' as funcao,
    '✅ Deve estar ativo' as observacao
UNION ALL
SELECT 
    'Triggers da Pasta' as info,
    'nova_regra_negocio_aulas.sql' as arquivo,
    'Validação por período' as funcao,
    '⚠️ Pode estar conflitando' as observacao
UNION ALL
SELECT 
    'Triggers da Pasta' as info,
    'resolver_conflito_triggers.sql' as arquivo,
    'Trigger básico sem conflitos' as funcao,
    '✅ Deve estar ativo' as observacao;

-- 8. Instruções para resolver
SELECT 
    'INSTRUÇÕES' as info,
    '1. Se há triggers conflitantes, execute resolver_conflito_triggers.sql' as passo_1,
    '2. Se trigger_horarios_automaticos não está ativo, execute o arquivo' as passo_2,
    '3. Se há funções problemáticas, desabilite-as temporariamente' as passo_3,
    '4. Teste a criação de aulas após resolver' as passo_4; 