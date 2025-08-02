-- Script simples para testar inserção de agendamentos
-- Execute este script no Supabase SQL Editor

-- 1. Verificar dados disponíveis
SELECT 'Dados Disponíveis' as info, 'Matérias' as tipo, COUNT(*) as quantidade FROM materias
UNION ALL
SELECT 'Dados Disponíveis' as info, 'Salas' as tipo, COUNT(*) as quantidade FROM salas
UNION ALL
SELECT 'Dados Disponíveis' as info, 'Cursos' as tipo, COUNT(*) as quantidade FROM cursos
UNION ALL
SELECT 'Dados Disponíveis' as info, 'Professores' as tipo, COUNT(*) as quantidade FROM professores;

-- 2. Pegar IDs válidos para teste
SELECT 
    'IDs Válidos para Teste' as info,
    (SELECT MIN(id) FROM materias) as materia_id,
    (SELECT MIN(id) FROM salas) as sala_id,
    (SELECT MIN(id) FROM cursos) as curso_id,
    (SELECT MIN(id) FROM professores) as professor_id;

-- 3. Desabilitar todos os triggers temporariamente
ALTER TABLE agendamento DISABLE TRIGGER ALL;

-- 4. Testar inserção simples
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
    professor_id_valido INTEGER;
    agendamento_id INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    SELECT MIN(id) INTO professor_id_valido FROM professores;
    
    -- Verificar se temos dados válidos
    IF materia_id_valido IS NULL OR sala_id_valido IS NULL OR curso_id_valido IS NULL OR professor_id_valido IS NULL THEN
        RAISE NOTICE '❌ Dados insuficientes para teste';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testando inserção com IDs: materia=%s, sala=%s, curso=%s, professor=%s', 
        materia_id_valido, sala_id_valido, curso_id_valido, professor_id_valido;
    
    -- Testar inserção válida
    BEGIN
        INSERT INTO agendamento (
            sala_id, curso_id, materia_id, professor_id,
            dia, aula_periodo, periodo, tipo_agendamento
        ) VALUES (
            sala_id_valido, curso_id_valido, materia_id_valido, professor_id_valido,
            (CURRENT_DATE + INTERVAL '4 days')::date, 'Primeira Aula', 1, 'A'
        ) RETURNING id INTO agendamento_id;
        
        RAISE NOTICE '✅ Inserção válida funcionou! ID criado: %s', agendamento_id;
        
        -- Verificar se foi realmente criado
        IF EXISTS (SELECT 1 FROM agendamento WHERE id = agendamento_id) THEN
            RAISE NOTICE '✅ Agendamento confirmado no banco de dados';
        ELSE
            RAISE NOTICE '❌ Agendamento não encontrado no banco de dados';
        END IF;
        
        -- Limpar teste
        DELETE FROM agendamento WHERE id = agendamento_id;
        RAISE NOTICE '🧹 Teste limpo com sucesso';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Inserção válida falhou: %s', SQLERRM;
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %s', SQLERRM;
END $$;

-- 5. Verificar estrutura da tabela agendamento
SELECT 
    'Estrutura da Tabela' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'agendamento' 
ORDER BY ordinal_position;

-- 6. Verificar triggers
SELECT 
    'Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    CASE 
        WHEN tgenabled = 'D' THEN '❌ Desabilitado'
        WHEN tgenabled = 'E' THEN '✅ Habilitado'
        ELSE '❓ Status desconhecido'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 7. Verificar agendamentos existentes
SELECT 
    'Agendamentos Existentes' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN tipo_agendamento = 'A' THEN 1 END) as aulas,
    COUNT(CASE WHEN tipo_agendamento = 'E' THEN 1 END) as eventos,
    COUNT(CASE WHEN tipo_agendamento = 'M' THEN 1 END) as provas
FROM agendamento 
WHERE dia >= CURRENT_DATE; 