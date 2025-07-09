-- Script para verificar quais triggers estão ativos na tabela agendamento

-- 1. Verificar todos os triggers da tabela agendamento
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    action_orientation
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 2. Verificar se os triggers estão habilitados
SELECT 
    schemaname,
    tablename,
    triggername,
    tgenabled
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
ORDER BY triggername;

-- 3. Verificar o conteúdo dos triggers
SELECT 
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE proname LIKE '%agendamento%'
ORDER BY proname; 