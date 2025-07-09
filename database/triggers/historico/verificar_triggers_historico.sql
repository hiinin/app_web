-- Script para verificar e corrigir os triggers de histórico
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

-- 2. Verificar se os triggers de histórico estão habilitados
SELECT 
    'Status dos Triggers' as info,
    schemaname,
    tablename,
    triggername,
    CASE 
        WHEN tgenabled = 'D' THEN 'DESABILITADO ❌'
        WHEN tgenabled = 'E' THEN 'HABILITADO ✅'
        WHEN tgenabled = 'A' THEN 'SEMPRE ✅'
        WHEN tgenabled = 'R' THEN 'REPLICA ✅'
        ELSE 'DESCONHECIDO ❓'
    END as status
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
ORDER BY triggername;

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

-- 4. Reabilitar todos os triggers de histórico
DO $$
BEGIN
    -- Reabilita todos os triggers da tabela agendamento
    ALTER TABLE agendamento ENABLE TRIGGER ALL;
    
    RAISE NOTICE 'Todos os triggers da tabela agendamento foram reabilitados';
END $$;

-- 5. Verificar novamente o status dos triggers
SELECT 
    'Status Após Reabilitação' as info,
    schemaname,
    tablename,
    triggername,
    CASE 
        WHEN tgenabled = 'D' THEN 'DESABILITADO ❌'
        WHEN tgenabled = 'E' THEN 'HABILITADO ✅'
        WHEN tgenabled = 'A' THEN 'SEMPRE ✅'
        WHEN tgenabled = 'R' THEN 'REPLICA ✅'
        ELSE 'DESCONHECIDO ❓'
    END as status
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
ORDER BY triggername;

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