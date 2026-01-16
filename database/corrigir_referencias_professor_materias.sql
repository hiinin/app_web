-- =====================================================
-- SCRIPT: Corrigir todas as referências a professor_materias
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- PASSO 1: Verificar todas as funções que referenciam professor_materias
SELECT 
    'Funções que referenciam professor_materias' as info,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_definition LIKE '%professor_materias%'
  AND routine_schema = 'public';

-- PASSO 2: Verificar todos os triggers que referenciam professor_materias
SELECT 
    'Triggers que referenciam professor_materias' as info,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE action_statement LIKE '%professor_materias%'
  AND trigger_schema = 'public';

-- PASSO 3: Verificar views que podem referenciar professor_materias
SELECT 
    'Views que referenciam professor_materias' as info,
    table_name,
    view_definition
FROM information_schema.views
WHERE view_definition LIKE '%professor_materias%'
  AND table_schema = 'public';

-- PASSO 4: Remover TODOS os triggers que referenciam professor_materias
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers
        WHERE action_statement LIKE '%professor_materias%'
          AND trigger_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I', 
            trigger_record.trigger_name, 
            trigger_record.event_object_table);
        RAISE NOTICE 'Trigger removido: % da tabela %', 
            trigger_record.trigger_name, 
            trigger_record.event_object_table;
    END LOOP;
END $$;

-- PASSO 5: Remover TODAS as funções que referenciam professor_materias
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT routine_name
        FROM information_schema.routines
        WHERE routine_definition LIKE '%professor_materias%'
          AND routine_schema = 'public'
          AND routine_type = 'FUNCTION'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I CASCADE', func_record.routine_name);
        RAISE NOTICE 'Função removida: %', func_record.routine_name;
    END LOOP;
END $$;

-- PASSO 6: Verificar se a tabela professor_turmas existe e tem a estrutura correta
SELECT 
    'Verificação da Tabela professor_turmas' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'professor_turmas'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- PASSO 7: Verificar constraints da tabela professor_turmas
SELECT 
    'Constraints da Tabela professor_turmas' as info,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'professor_turmas'
  AND table_schema = 'public';

-- PASSO 8: Verificar se há alguma referência restante a professor_materias
SELECT 
    'Verificação Final - Referências Restantes' as info,
    'Funções' as tipo,
    COUNT(*) as quantidade
FROM information_schema.routines
WHERE routine_definition LIKE '%professor_materias%'
  AND routine_schema = 'public'
UNION ALL
SELECT 
    'Verificação Final - Referências Restantes' as info,
    'Triggers' as tipo,
    COUNT(*) as quantidade
FROM information_schema.triggers
WHERE action_statement LIKE '%professor_materias%'
  AND trigger_schema = 'public'
UNION ALL
SELECT 
    'Verificação Final - Referências Restantes' as info,
    'Views' as tipo,
    COUNT(*) as quantidade
FROM information_schema.views
WHERE view_definition LIKE '%professor_materias%'
  AND table_schema = 'public';

-- PASSO 9: Verificar se os triggers de professor_turmas estão ativos
SELECT 
    'Triggers Ativos de professor_turmas' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    CASE 
        WHEN tgenabled = 'D' THEN '❌ Desabilitado'
        WHEN tgenabled = 'E' THEN '✅ Habilitado'
        ELSE '❓ Status desconhecido'
    END as status
FROM information_schema.triggers
WHERE event_object_table = 'professor_turmas'
ORDER BY trigger_name;






