-- Script para identificar e remover funções antigas que podem conflitar
-- Execute este script no Supabase SQL Editor APÓS verificar os resultados

-- 1. PRIMEIRO: Identificar funções que podem ter regras antigas

-- Funções que podem ter limite de 6 alocações por dia
SELECT 
    'Funções com Limite 6 (ANTIGO)' as categoria,
    proname as nome_funcao,
    'Possível conflito com nova regra (limite 12)' as problema,
    'DROP FUNCTION IF EXISTS ' || proname || '();' as comando_remocao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
  AND (prosrc LIKE '%6%' OR prosrc LIKE '%seis%')
  AND proname NOT IN ('definir_horarios_agendamento', 'contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario')
ORDER BY proname;

-- Funções que podem ter regra de 1 curso por horário
SELECT 
    'Funções com 1 Curso por Horário (ANTIGO)' as categoria,
    proname as nome_funcao,
    'Possível conflito com nova regra (2 cursos por horário)' as problema,
    'DROP FUNCTION IF EXISTS ' || proname || '();' as comando_remocao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
  AND (prosrc LIKE '%1%curso%' OR prosrc LIKE '%um%curso%' OR prosrc LIKE '%único%curso%')
  AND proname NOT IN ('definir_horarios_agendamento', 'contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario')
ORDER BY proname;

-- Funções que podem ter validações de conflito antigas
SELECT 
    'Funções com Validação Antiga' as categoria,
    proname as nome_funcao,
    'Possível conflito com novas regras' as problema,
    'DROP FUNCTION IF EXISTS ' || proname || '();' as comando_remocao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
  AND (prosrc LIKE '%conflito%' OR prosrc LIKE '%bloquear%' OR prosrc LIKE '%impedir%')
  AND proname NOT IN ('definir_horarios_agendamento', 'contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario')
  AND proname NOT LIKE '%definir_horarios%'
ORDER BY proname;

-- 2. SEGUNDO: Verificar triggers que podem estar usando funções antigas

-- Triggers que não usam a função principal
SELECT 
    'Triggers com Funções Antigas' as categoria,
    trigger_name,
    action_statement,
    'ALTER TABLE agendamento DISABLE TRIGGER ' || trigger_name || ';' as comando_desabilitar,
    'DROP TRIGGER IF EXISTS ' || trigger_name || ' ON agendamento;' as comando_remover
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND action_statement NOT LIKE '%definir_horarios_agendamento%'
  AND trigger_name LIKE '%validar%'
ORDER BY trigger_name;

-- 3. TERCEIRO: Comandos para remoção (execute apenas se necessário)

-- DESCOMENTE AS LINHAS ABAIXO APENAS SE VOCÊ CONFIRMAR QUE SÃO FUNÇÕES ANTIGAS
-- E QUE NÃO ESTÃO SENDO USADAS POR OUTROS TRIGGERS

/*
-- Exemplo de remoção de funções antigas (descomente se necessário)
-- DROP FUNCTION IF EXISTS nome_da_funcao_antiga();

-- Exemplo de desabilitação de triggers antigos (descomente se necessário)
-- ALTER TABLE agendamento DISABLE TRIGGER nome_do_trigger_antigo;
-- DROP TRIGGER IF EXISTS nome_do_trigger_antigo ON agendamento;
*/

-- 4. QUARTO: Verificar se há outras funções relacionadas ao agendamento

-- Listar todas as funções relacionadas ao agendamento para análise
SELECT 
    'Todas as Funções de Agendamento' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN proname IN ('definir_horarios_agendamento', 'contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario') THEN '✅ NOVAS FUNÇÕES'
        WHEN prosrc LIKE '%6%' OR prosrc LIKE '%seis%' THEN '⚠️ POSSÍVEL ANTIGA'
        WHEN prosrc LIKE '%1%curso%' OR prosrc LIKE '%um%curso%' THEN '⚠️ POSSÍVEL ANTIGA'
        WHEN prosrc LIKE '%conflito%' THEN '⚠️ POSSÍVEL ANTIGA'
        ELSE '🔍 VERIFICAR'
    END as status
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
ORDER BY proname;

-- 5. QUINTO: Instruções finais

SELECT 
    'INSTRUÇÕES PARA LIMPEZA' as categoria,
    '1. Execute este script para identificar funções antigas' as passo_1,
    '2. Analise os resultados e identifique funções que podem ser removidas' as passo_2,
    '3. Descomente os comandos de remoção apenas se tiver certeza' as passo_3,
    '4. Execute os comandos de remoção um por vez' as passo_4,
    '5. Teste o sistema após cada remoção' as passo_5;

-- 6. SEXTO: Verificação final

-- Verificar se o sistema está funcionando corretamente
SELECT 
    'VERIFICAÇÃO FINAL' as categoria,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'definir_horarios_agendamento'
        ) THEN '✅ Função principal existe'
        ELSE '❌ Função principal não encontrada'
    END as funcao_principal,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'contar_alocacoes_sala_dia'
        ) THEN '✅ Função auxiliar 1 existe'
        ELSE '❌ Função auxiliar 1 não encontrada'
    END as funcao_auxiliar_1,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'contar_cursos_mesmo_horario'
        ) THEN '✅ Função auxiliar 2 existe'
        ELSE '❌ Função auxiliar 2 não encontrada'
    END as funcao_auxiliar_2,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'curso_ja_alocado_horario'
        ) THEN '✅ Função auxiliar 3 existe'
        ELSE '❌ Função auxiliar 3 não encontrada'
    END as funcao_auxiliar_3; 