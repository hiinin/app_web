-- Script para reabilitar especificamente os triggers de histórico
-- Execute este script no Supabase SQL Editor

-- 1. Reabilitar os triggers de histórico que estão desabilitados
DO $$
BEGIN
    -- Reabilita os triggers de log de agendamento
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_insert') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_insert;
        RAISE NOTICE '✅ Trigger trigger_log_agendamento_insert reabilitado';
    ELSE
        RAISE NOTICE '❌ Trigger trigger_log_agendamento_insert não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_update') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_update;
        RAISE NOTICE '✅ Trigger trigger_log_agendamento_update reabilitado';
    ELSE
        RAISE NOTICE '❌ Trigger trigger_log_agendamento_update não encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_delete') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_log_agendamento_delete;
        RAISE NOTICE '✅ Trigger trigger_log_agendamento_delete reabilitado';
    ELSE
        RAISE NOTICE '❌ Trigger trigger_log_agendamento_delete não encontrado';
    END IF;
    
    RAISE NOTICE '🎉 Todos os triggers de histórico foram reabilitados!';
END $$;

-- 2. Verificar o status após reabilitação
SELECT 
    'Status Final dos Triggers' as info,
    tgname as trigger_name,
    CASE 
        WHEN tgenabled = 'D' THEN 'DESABILITADO ❌'
        WHEN tgenabled = 'E' THEN 'HABILITADO ✅'
        WHEN tgenabled = 'A' THEN 'SEMPRE ✅'
        WHEN tgenabled = 'R' THEN 'REPLICA ✅'
        ELSE 'DESCONHECIDO ❓'
    END as status
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
  AND tgname LIKE '%log%'
ORDER BY tgname;

-- 3. Testar se está funcionando
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
    agendamento_id INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    
    RAISE NOTICE '🧪 Iniciando teste de inserção...';
    
    -- Testar inserção
    INSERT INTO agendamento (
        aula_periodo, 
        sala_id, 
        curso_id, 
        materia_id, 
        dia, 
        periodo, 
        tipo_agendamento
    ) VALUES (
        'Primeira Aula', 
        sala_id_valido, 
        curso_id_valido, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '1 day')::date, 
        1, 
        'T'
    ) RETURNING id INTO agendamento_id;
    
    RAISE NOTICE '📝 Agendamento criado com ID: %', agendamento_id;
    
    -- Aguardar um pouco para o trigger executar
    PERFORM pg_sleep(0.5);
    
    -- Verificar se o histórico foi criado
    IF EXISTS (
        SELECT 1 FROM historico_acoes 
        WHERE tabela_afetada = 'agendamento' 
          AND registro_id = agendamento_id
          AND acao = 'INSERT'
    ) THEN
        RAISE NOTICE '✅ Histórico criado com sucesso!';
    ELSE
        RAISE NOTICE '❌ Histórico NÃO foi criado!';
    END IF;
    
    -- Limpar o teste
    DELETE FROM agendamento WHERE id = agendamento_id;
    DELETE FROM historico_acoes WHERE registro_id = agendamento_id;
    
    RAISE NOTICE '🧹 Teste limpo com sucesso!';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erro no teste: %', SQLERRM;
END $$;

-- 4. Verificar registros recentes no histórico
SELECT 
    'Histórico Recente (últimos 5 minutos)' as info,
    id,
    tabela_afetada,
    acao,
    registro_id,
    detalhes,
    data_hora
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND data_hora >= NOW() - INTERVAL '5 minutes'
ORDER BY data_hora DESC
LIMIT 10; 