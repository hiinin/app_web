-- Script simples para configurar agendamento múltiplo
-- Execute este script no Supabase SQL Editor

-- 1. Verificar triggers existentes
SELECT 
    'Triggers da Tabela Agendamento' as info,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 2. Desabilitar triggers de log específicos
DO $$
BEGIN
    -- Desabilita triggers de log se existirem
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_insert') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_insert;
        RAISE NOTICE 'Trigger trigger_log_agendamento_insert desabilitado';
    ELSE
        RAISE NOTICE 'Trigger trigger_log_agendamento_insert não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_update') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_update;
        RAISE NOTICE 'Trigger trigger_log_agendamento_update desabilitado';
    ELSE
        RAISE NOTICE 'Trigger trigger_log_agendamento_update não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_delete') THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_log_agendamento_delete;
        RAISE NOTICE 'Trigger trigger_log_agendamento_delete desabilitado';
    ELSE
        RAISE NOTICE 'Trigger trigger_log_agendamento_delete não encontrado';
    END IF;
    
    -- Desabilita outros triggers de log se existirem
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_insert') THEN
        ALTER TABLE agendamento DISABLE TRIGGER registrar_historico_agendamento_insert;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_insert desabilitado';
    ELSE
        RAISE NOTICE 'Trigger registrar_historico_agendamento_insert não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_update') THEN
        ALTER TABLE agendamento DISABLE TRIGGER registrar_historico_agendamento_update;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_update desabilitado';
    ELSE
        RAISE NOTICE 'Trigger registrar_historico_agendamento_update não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_delete') THEN
        ALTER TABLE agendamento DISABLE TRIGGER registrar_historico_agendamento_delete;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_delete desabilitado';
    ELSE
        RAISE NOTICE 'Trigger registrar_historico_agendamento_delete não encontrado';
    END IF;
    
    RAISE NOTICE 'Configuração de triggers concluída';
END $$;

-- 3. Verificar status dos triggers
SELECT 
    'Status dos Triggers' as info,
    trigger_name,
    CASE 
        WHEN trigger_name LIKE 'RI_%' THEN 'SISTEMA'
        WHEN trigger_name LIKE '%log%' OR trigger_name LIKE '%historico%' THEN 'LOG'
        ELSE 'OUTRO'
    END as tipo
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 4. Limpar registros duplicados do histórico
DELETE FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao = 'INSERT' 
  AND data_hora >= NOW() - INTERVAL '24 hours'
  AND id IN (
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

-- 5. Verificar histórico após limpeza
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

-- 6. Criar funções de controle
CREATE OR REPLACE FUNCTION desabilitar_triggers_log_agendamento()
RETURNS void AS $$
BEGIN
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

-- 7. Verificar funções criadas
SELECT 
  'Funções Criadas' as info,
  routine_name
FROM information_schema.routines 
WHERE routine_name IN (
  'desabilitar_triggers_log_agendamento', 
  'reabilitar_triggers_log_agendamento'
)
ORDER BY routine_name; 