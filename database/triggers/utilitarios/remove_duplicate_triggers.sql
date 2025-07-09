-- SQL para remover os triggers duplicados que estão causando registros duplicados
-- Remove os 3 primeiros triggers (trigger_agendamento_*)

-- 1. Remover trigger_agendamento_delete
DROP TRIGGER IF EXISTS trigger_agendamento_delete ON agendamento;

-- 2. Remover trigger_agendamento_insert  
DROP TRIGGER IF EXISTS trigger_agendamento_insert ON agendamento;

-- 3. Remover trigger_agendamento_update
DROP TRIGGER IF EXISTS trigger_agendamento_update ON agendamento;

-- Verificar se os triggers foram removidos
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers 
WHERE trigger_name LIKE 'trigger_agendamento%'
ORDER BY trigger_name; 