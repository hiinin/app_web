-- Funções para desabilitar e reabilitar triggers do agendamento
-- Isso permite criar agendamentos múltiplos sem gerar registros duplicados no histórico

-- Função para desabilitar os triggers
CREATE OR REPLACE FUNCTION disable_agendamento_triggers()
RETURNS void AS $$
BEGIN
  -- Desabilita os triggers de log do agendamento
  ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_insert;
  ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_update;
  ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_delete;
END;
$$ LANGUAGE plpgsql;

-- Função para reabilitar os triggers
CREATE OR REPLACE FUNCTION enable_agendamento_triggers()
RETURNS void AS $$
BEGIN
  -- Reabilita os triggers de log do agendamento
  ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_insert;
  ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_update;
  ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_delete;
END;
$$ LANGUAGE plpgsql;

-- Verificar se as funções foram criadas
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN ('disable_agendamento_triggers', 'enable_agendamento_triggers')
ORDER BY routine_name; 