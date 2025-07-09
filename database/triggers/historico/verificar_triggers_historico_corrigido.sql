-- Script corrigido para verificar e corrigir os triggers de histórico no Supabase
-- Execute este script no Supabase SQL Editor

-- 1. Verificar todos os triggers da tabela agendamento
SELECT 
    'Triggers da Tabela Agendamento' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 2. Verificar se os triggers de histórico estão habilitados (versão corrigida)
SELECT 
    'Status dos Triggers' as info,
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
ORDER BY tgname;

-- 3. Verificar se as funções de histórico existem
SELECT 
    'Funções de Histórico' as info,
    proname as nome_funcao,
    CASE 
        WHEN proname LIKE '%historico%' OR proname LIKE '%log%' THEN 'HISTÓRICO'
        ELSE 'OUTRA'
    END as tipo
FROM pg_proc 
WHERE proname LIKE '%historico%' 
   OR proname LIKE '%log%'
   OR proname LIKE '%agendamento%'
ORDER BY proname;

-- 4. Reabilitar apenas os triggers de histórico (não os do sistema)
DO $$
BEGIN
    -- Reabilita apenas os triggers específicos de histórico
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_agendamento_insert') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_agendamento_insert;
        RAISE NOTICE 'Trigger trigger_agendamento_insert reabilitado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_agendamento_update') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_agendamento_update;
        RAISE NOTICE 'Trigger trigger_agendamento_update reabilitado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_agendamento_delete') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_agendamento_delete;
        RAISE NOTICE 'Trigger trigger_agendamento_delete reabilitado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_definir_horarios') THEN
        ALTER TABLE agendamento ENABLE TRIGGER trigger_definir_horarios;
        RAISE NOTICE 'Trigger trigger_definir_horarios reabilitado';
    END IF;
    
    RAISE NOTICE 'Triggers de histórico reabilitados com sucesso';
END $$;

-- 5. Verificar novamente o status dos triggers
SELECT 
    'Status Após Reabilitação' as info,
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
ORDER BY tgname;

-- 6. Testar inserção para verificar se o histórico está funcionando
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
    
    RAISE NOTICE 'Agendamento criado com ID: %', agendamento_id;
    
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
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;

-- 7. Verificar registros recentes no histórico
SELECT 
    'Histórico Recente' as info,
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