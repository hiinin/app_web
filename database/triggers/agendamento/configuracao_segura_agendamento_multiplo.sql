-- Script seguro para configurar agendamento múltiplo
-- Desabilita apenas os triggers de log, não os triggers do sistema

-- 1. Primeiro, vamos verificar quais triggers existem
SELECT 
    'Triggers Existentes' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    CASE 
        WHEN trigger_name LIKE 'RI_%' THEN 'SISTEMA'
        WHEN trigger_name LIKE '%log%' OR trigger_name LIKE '%historico%' THEN 'LOG'
        ELSE 'OUTRO'
    END as tipo_trigger
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 2. Desabilitar apenas os triggers de log (não os do sistema)
-- Desabilita triggers específicos de log do agendamento
DO $$
BEGIN
    -- Desabilita triggers de log se existirem
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_insert') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_insert;
        RAISE NOTICE 'Trigger trigger_log_agendamento_insert desabilitado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_update') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_update;
        RAISE NOTICE 'Trigger trigger_log_agendamento_update desabilitado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_delete') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_delete;
        RAISE NOTICE 'Trigger trigger_log_agendamento_delete desabilitado';
    END IF;
    
    -- Desabilita outros triggers de log se existirem
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_insert') THEN
        ALTER TABLE agendamento DISABLE TRIGGER registrar_historico_agendamento_insert;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_insert desabilitado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_update') THEN
        ALTER TABLE agendamento DISABLE TRIGGER registrar_historico_agendamento_update;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_update desabilitado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_delete') THEN
        ALTER TABLE agendamento DISABLE TRIGGER registrar_historico_agendamento_delete;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_delete desabilitado';
    END IF;
    
    RAISE NOTICE 'Configuração de triggers concluída';
END $$;

-- 3. Verificar o status dos triggers após a configuração
SELECT 
    'Status dos Triggers' as info,
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    CASE 
        WHEN t.tgenabled = 'D' THEN 'DESABILITADO ✅'
        WHEN t.tgenabled = 'E' THEN 'HABILITADO ❌'
        WHEN t.tgenabled = 'A' THEN 'SEMPRE ❌'
        WHEN t.tgenabled = 'R' THEN 'REPLICA ❌'
        ELSE 'DESCONHECIDO ❌'
    END as status,
    CASE 
        WHEN t.tgname LIKE 'RI_%' THEN 'SISTEMA'
        WHEN t.tgname LIKE '%log%' OR t.tgname LIKE '%historico%' THEN 'LOG'
        ELSE 'OUTRO'
    END as tipo
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relname = 'agendamento'
ORDER BY t.tgname;

-- 4. Limpar registros duplicados existentes no histórico
DELETE FROM historico_acoes 
WHERE id IN (
  SELECT h1.id
  FROM historico_acoes h1
  WHERE h1.tabela_afetada = 'agendamento' 
    AND h1.acao = 'INSERT'
    AND h1.data_hora >= NOW() - INTERVAL '24 hours'
    AND EXISTS (
      SELECT 1 
      FROM historico_acoes h2
      WHERE h2.tabela_afetada = 'agendamento' 
        AND h2.acao = 'INSERT'
        AND h2.data_hora >= NOW() - INTERVAL '24 hours'
        AND h2.id != h1.id
        AND ABS(EXTRACT(EPOCH FROM (h2.data_hora - h1.data_hora))) <= 30
    )
);

-- 5. Verificar o resultado da limpeza
SELECT 
  'Histórico Após Limpeza' as status,
  acao,
  COUNT(*) as quantidade
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao IN ('INSERT', 'INSERT_MULTIPLE')
  AND data_hora >= NOW() - INTERVAL '24 hours'
GROUP BY acao
ORDER BY acao;

-- 6. Criar funções de controle mais específicas
CREATE OR REPLACE FUNCTION desabilitar_triggers_log_agendamento()
RETURNS void AS $$
BEGIN
    -- Desabilita apenas os triggers de log
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_insert') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_insert;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_update') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_update;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_delete') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_delete;
    END IF;
    
    RAISE NOTICE 'Triggers de log do agendamento desabilitados';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reabilitar_triggers_log_agendamento()
RETURNS void AS $$
BEGIN
    -- Reabilita apenas os triggers de log
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_insert') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_insert;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_update') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_update;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_delete') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_delete;
    END IF;
    
    RAISE NOTICE 'Triggers de log do agendamento reabilitados';
END;
$$ LANGUAGE plpgsql;

-- 7. Verificar se as funções foram criadas
SELECT 
  'Funções Criadas' as info,
  routine_name,
  routine_type
FROM information_schema.routines 
WHERE routine_name IN (
  'desabilitar_triggers_log_agendamento', 
  'reabilitar_triggers_log_agendamento'
)
ORDER BY routine_name; 