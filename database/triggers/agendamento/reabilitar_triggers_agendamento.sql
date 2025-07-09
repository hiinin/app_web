-- Script para reabilitar os triggers de log do agendamento
-- Execute este script para restaurar o funcionamento normal

-- 1. Reabilitar todos os triggers de log
DO $$
BEGIN
    -- Reabilita triggers de log se existirem
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_insert') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_insert;
        RAISE NOTICE 'Trigger trigger_log_agendamento_insert reabilitado';
    ELSE
        RAISE NOTICE 'Trigger trigger_log_agendamento_insert não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_update') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_update;
        RAISE NOTICE 'Trigger trigger_log_agendamento_update reabilitado';
    ELSE
        RAISE NOTICE 'Trigger trigger_log_agendamento_update não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_delete') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_delete;
        RAISE NOTICE 'Trigger trigger_log_agendamento_delete reabilitado';
    ELSE
        RAISE NOTICE 'Trigger trigger_log_agendamento_delete não encontrado';
    END IF;
    
    -- Reabilita outros triggers de log se existirem
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_insert') THEN
        ALTER TABLE agendamento ENABLE TRIGGER registrar_historico_agendamento_insert;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_insert reabilitado';
    ELSE
        RAISE NOTICE 'Trigger registrar_historico_agendamento_insert não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_update') THEN
        ALTER TABLE agendamento ENABLE TRIGGER registrar_historico_agendamento_update;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_update reabilitado';
    ELSE
        RAISE NOTICE 'Trigger registrar_historico_agendamento_update não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'registrar_historico_agendamento_delete') THEN
        ALTER TABLE agendamento ENABLE TRIGGER registrar_historico_agendamento_delete;
        RAISE NOTICE 'Trigger registrar_historico_agendamento_delete reabilitado';
    ELSE
        RAISE NOTICE 'Trigger registrar_historico_agendamento_delete não encontrado';
    END IF;
    
    RAISE NOTICE 'Todos os triggers de log foram reabilitados';
END $$;

-- 2. Verificar status dos triggers
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

-- 3. Testar se os triggers estão funcionando
-- Criar um agendamento de teste para verificar se os triggers estão ativos
INSERT INTO agendamento (
    aula_periodo, 
    sala_id, 
    curso_id, 
    materia_id, 
    dia, 
    periodo, 
    tipo_agendamento
) VALUES (
    'Teste', 
    1, 
    1, 
    1, 
    '2025-01-01', 
    1, 
    'T'
) ON CONFLICT DO NOTHING;

-- 4. Verificar se o registro foi criado no histórico
SELECT 
    'Teste de Trigger' as info,
    id,
    tabela_afetada,
    acao,
    detalhes,
    data_hora
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND data_hora >= NOW() - INTERVAL '5 minutes'
ORDER BY data_hora DESC
LIMIT 5;

-- 5. Remover o agendamento de teste
DELETE FROM agendamento WHERE tipo_agendamento = 'T'; 