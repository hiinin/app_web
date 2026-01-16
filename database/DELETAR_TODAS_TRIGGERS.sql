-- =====================================================
-- SCRIPT: Deletar TODAS as triggers do banco
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- PASSO 1: Desabilitar TODAS as triggers de todas as tabelas
DO $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN 
        SELECT DISTINCT event_object_table
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %I DISABLE TRIGGER ALL', table_record.event_object_table);
            RAISE NOTICE '✅ Triggers desabilitadas na tabela: %', table_record.event_object_table;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Erro ao desabilitar triggers da tabela %: %', 
                table_record.event_object_table, SQLERRM;
        END;
    END LOOP;
END $$;

-- PASSO 2: Listar todas as triggers antes de deletar
SELECT 
    '🔍 Triggers que serão deletadas' as info,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- PASSO 3: Deletar TODAS as triggers
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I CASCADE', 
                trigger_record.trigger_name, 
                trigger_record.event_object_table);
            RAISE NOTICE '✅ Trigger deletada: % da tabela %', 
                trigger_record.trigger_name, 
                trigger_record.event_object_table;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Erro ao deletar trigger %: %', 
                trigger_record.trigger_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- PASSO 4: Verificar se todas as triggers foram deletadas
SELECT 
    '✅ Verificação Final' as info,
    COUNT(*) as triggers_restantes
FROM information_schema.triggers
WHERE trigger_schema = 'public';

-- Se retornar 0, todas as triggers foram deletadas com sucesso!






