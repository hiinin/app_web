-- Script para listar todas as funções relacionadas ao sistema de agendamento no Supabase
-- Execute este script no Supabase SQL Editor

-- 1. Listar TODAS as funções que contêm palavras relacionadas ao agendamento
SELECT 
    'Todas as Funções de Agendamento' as categoria,
    proname as nome_funcao,
    prosrc as codigo_funcao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
   OR prosrc LIKE '%aula%'
   OR prosrc LIKE '%sala%'
   OR prosrc LIKE '%horario%'
   OR prosrc LIKE '%conflito%'
   OR prosrc LIKE '%validar%'
   OR prosrc LIKE '%periodo%'
ORDER BY proname;

-- 2. Listar funções que são chamadas por triggers
SELECT 
    'Funções dos Triggers' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%definir_horarios%' THEN '🕐 Horários Automáticos'
        WHEN prosrc LIKE '%validar%' THEN '✅ Validação'
        WHEN prosrc LIKE '%conflito%' THEN '⚠️ Conflito'
        WHEN prosrc LIKE '%historico%' THEN '📝 Histórico'
        WHEN prosrc LIKE '%periodo%' THEN '📅 Período'
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

-- 3. Listar funções específicas que podem estar relacionadas às regras de negócio
SELECT 
    'Funções de Validação' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%validar_aula%' THEN '✅ Validação de Aula'
        WHEN prosrc LIKE '%validar_agendamento%' THEN '✅ Validação de Agendamento'
        WHEN prosrc LIKE '%conflito_sala%' THEN '⚠️ Conflito de Sala'
        WHEN prosrc LIKE '%verificar_disponibilidade%' THEN '🔍 Verificar Disponibilidade'
        WHEN prosrc LIKE '%contar_uso_sala%' THEN '📊 Contar Uso da Sala'
        WHEN prosrc LIKE '%validar_periodo%' THEN '📅 Validação de Período'
        ELSE '🔧 Outro'
    END as tipo_funcao
FROM pg_proc 
WHERE prosrc LIKE '%validar%'
   OR prosrc LIKE '%conflito%'
   OR prosrc LIKE '%verificar%'
   OR prosrc LIKE '%contar%'
   OR prosrc LIKE '%periodo%'
ORDER BY proname;

-- 4. Listar funções que podem estar relacionadas às novas regras
SELECT 
    'Funções para Novas Regras' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%12%' OR prosrc LIKE '%doze%' THEN '🔢 Limite 12'
        WHEN prosrc LIKE '%2%curso%' OR prosrc LIKE '%dois%curso%' THEN '👥 2 Cursos por Horário'
        WHEN prosrc LIKE '%compartilhar%' OR prosrc LIKE '%compartilhamento%' THEN '🤝 Compartilhamento'
        WHEN prosrc LIKE '%turma%' THEN '👨‍🎓 Turmas'
        ELSE '🔧 Outro'
    END as tipo_funcao
FROM pg_proc 
WHERE prosrc LIKE '%12%'
   OR prosrc LIKE '%doze%'
   OR prosrc LIKE '%2%curso%'
   OR prosrc LIKE '%dois%curso%'
   OR prosrc LIKE '%compartilhar%'
   OR prosrc LIKE '%turma%'
ORDER BY proname;

-- 5. Listar funções que podem precisar de atualização
SELECT 
    'Funções para Atualizar' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%6%' OR prosrc LIKE '%seis%' THEN '⚠️ Limite 6 (antigo)'
        WHEN prosrc LIKE '%1%curso%' OR prosrc LIKE '%um%curso%' THEN '⚠️ 1 Curso por Horário (antigo)'
        WHEN prosrc LIKE '%bloquear%' THEN '⚠️ Bloqueio (pode precisar ajuste)'
        ELSE '🔧 Outro'
    END as tipo_funcao
FROM pg_proc 
WHERE prosrc LIKE '%6%'
   OR prosrc LIKE '%seis%'
   OR prosrc LIKE '%1%curso%'
   OR prosrc LIKE '%um%curso%'
   OR prosrc LIKE '%bloquear%'
ORDER BY proname;

-- 6. Resumo das funções encontradas
SELECT 
    'RESUMO' as categoria,
    COUNT(*) as total_funcoes,
    'Funções relacionadas ao agendamento encontradas' as descricao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
   OR prosrc LIKE '%aula%'
   OR prosrc LIKE '%sala%'
   OR prosrc LIKE '%horario%'
   OR prosrc LIKE '%conflito%'
   OR prosrc LIKE '%validar%'
   OR prosrc LIKE '%periodo%';

-- 7. Instruções para próximos passos
SELECT 
    'PRÓXIMOS PASSOS' as categoria,
    '1. Identifique as funções que precisam ser atualizadas' as passo_1,
    '2. Verifique as funções que usam limite 6 ou 1 curso por horário' as passo_2,
    '3. Atualize as funções para usar limite 12 e 2 cursos por horário' as passo_3,
    '4. Teste as novas regras após as atualizações' as passo_4; 