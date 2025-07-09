-- Remove a coluna local_externo da tabela agendamento
-- Execute este comando no Supabase SQL Editor

ALTER TABLE agendamento DROP COLUMN IF EXISTS local_externo;

-- Verifica se a coluna foi removida
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'agendamento' 
ORDER BY ordinal_position; 