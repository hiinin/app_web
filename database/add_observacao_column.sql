-- SQL para adicionar o campo observacao na tabela agendamento
-- Execute este script no seu banco de dados PostgreSQL/Supabase

ALTER TABLE public.agendamento
ADD COLUMN IF NOT EXISTS observacao TEXT NULL;

-- Comentário opcional para documentar a coluna
COMMENT ON COLUMN public.agendamento.observacao IS 'Campo opcional para observações sobre o agendamento';

