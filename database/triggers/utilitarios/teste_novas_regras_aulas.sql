-- Script de teste para as novas regras de negócio para aulas
-- Execute este script no Supabase SQL Editor para verificar se as regras estão funcionando

-- 1. Limpar dados de teste anteriores
DELETE FROM agendamento WHERE dia >= CURRENT_DATE AND tipo_agendamento = 'A';

-- 2. Verificar dados disponíveis para teste
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Matérias' as tipo,
    COUNT(*) as quantidade
FROM materias
UNION ALL
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Salas' as tipo,
    COUNT(*) as quantidade
FROM salas
UNION ALL
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Cursos' as tipo,
    COUNT(*) as quantidade
FROM cursos
UNION ALL
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Professores' as tipo,
    COUNT(*) as quantidade
FROM professores;

-- 3. Função para criar agendamento de teste
CREATE OR REPLACE FUNCTION criar_agendamento_teste(
    p_sala_id INTEGER,
    p_curso_id INTEGER,
    p_materia_id BIGINT,
    p_professor_id INTEGER,
    p_dia DATE,
    p_aula_periodo TEXT,
    p_periodo INTEGER
) RETURNS INTEGER AS $$
DECLARE
    agendamento_id INTEGER;
BEGIN
    INSERT INTO agendamento (
        sala_id,
        curso_id,
        materia_id,
        professor_id,
        dia,
        aula_periodo,
        periodo,
        tipo_agendamento
    ) VALUES (
        p_sala_id,
        p_curso_id,
        p_materia_id,
        p_professor_id,
        p_dia,
        p_aula_periodo,
        p_periodo,
        'A'
    ) RETURNING id INTO agendamento_id;
    
    RETURN agendamento_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Executar testes das novas regras
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido1 INTEGER;
    curso_id_valido2 INTEGER;
    curso_id_valido3 INTEGER;
    professor_id_valido INTEGER;
    dia_teste DATE;
    agendamento_id1 INTEGER;
    agendamento_id2 INTEGER;
    agendamento_id3 INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido1 FROM cursos;
    SELECT MIN(id) INTO professor_id_valido FROM professores;
    
    -- Pegar cursos diferentes
    SELECT MIN(id) INTO curso_id_valido2 
    FROM cursos 
    WHERE id != curso_id_valido1;
    
    SELECT MIN(id) INTO curso_id_valido3 
    FROM cursos 
    WHERE id != curso_id_valido1 AND id != curso_id_valido2;
    
    -- Se não houver cursos suficientes, criar alguns
    IF curso_id_valido2 IS NULL THEN
        INSERT INTO cursos (curso, periodo) VALUES ('Curso Teste 2', 2) RETURNING id INTO curso_id_valido2;
    END IF;
    
    IF curso_id_valido3 IS NULL THEN
        INSERT INTO cursos (curso, periodo) VALUES ('Curso Teste 3', 3) RETURNING id INTO curso_id_valido3;
    END IF;
    
    -- Definir dia de teste
    dia_teste := CURRENT_DATE + INTERVAL '1 day';
    
    RAISE NOTICE '=== INICIANDO TESTES DAS NOVAS REGRAS ===';
    RAISE NOTICE 'Dia de teste: %', dia_teste;
    RAISE NOTICE 'Sala ID: %, Materia ID: %, Professor ID: %', sala_id_valido, materia_id_valido, professor_id_valido;
    RAISE NOTICE 'Curso 1 ID: %, Curso 2 ID: %, Curso 3 ID: %', curso_id_valido1, curso_id_valido2, curso_id_valido3;
    
    -- TESTE 1: Criar primeira aula (deve funcionar)
    RAISE NOTICE '--- TESTE 1: Criar primeira aula ---';
    BEGIN
        agendamento_id1 := criar_agendamento_teste(
            sala_id_valido, curso_id_valido1, materia_id_valido, professor_id_valido,
            dia_teste, 'Primeira Aula', 1
        );
        RAISE NOTICE '✅ TESTE 1 PASSOU: Primeira aula criada com ID %', agendamento_id1;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ TESTE 1 FALHOU: %', SQLERRM;
    END;
    
    -- TESTE 2: Criar segunda aula no mesmo horário com curso diferente (deve funcionar)
    RAISE NOTICE '--- TESTE 2: Criar segunda aula no mesmo horário ---';
    BEGIN
        agendamento_id2 := criar_agendamento_teste(
            sala_id_valido, curso_id_valido2, materia_id_valido, professor_id_valido,
            dia_teste, 'Primeira Aula', 2
        );
        RAISE NOTICE '✅ TESTE 2 PASSOU: Segunda aula criada com ID %', agendamento_id2;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ TESTE 2 FALHOU: %', SQLERRM;
    END;
    
    -- TESTE 3: Tentar criar terceira aula no mesmo horário (deve falhar)
    RAISE NOTICE '--- TESTE 3: Tentar criar terceira aula no mesmo horário ---';
    BEGIN
        agendamento_id3 := criar_agendamento_teste(
            sala_id_valido, curso_id_valido3, materia_id_valido, professor_id_valido,
            dia_teste, 'Primeira Aula', 3
        );
        RAISE NOTICE '❌ TESTE 3 FALHOU: Terceira aula foi criada (não deveria) com ID %', agendamento_id3;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '✅ TESTE 3 PASSOU: Falhou corretamente - %', SQLERRM;
    END;
    
    -- TESTE 4: Tentar criar aula com curso já agendado no mesmo horário (deve falhar)
    RAISE NOTICE '--- TESTE 4: Tentar criar aula com curso já agendado ---';
    BEGIN
        agendamento_id3 := criar_agendamento_teste(
            sala_id_valido, curso_id_valido1, materia_id_valido, professor_id_valido,
            dia_teste, 'Primeira Aula', 1
        );
        RAISE NOTICE '❌ TESTE 4 FALHOU: Aula com curso duplicado foi criada (não deveria) com ID %', agendamento_id3;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '✅ TESTE 4 PASSOU: Falhou corretamente - %', SQLERRM;
    END;
    
    -- TESTE 5: Criar aula em horário diferente (deve funcionar)
    RAISE NOTICE '--- TESTE 5: Criar aula em horário diferente ---';
    BEGIN
        agendamento_id3 := criar_agendamento_teste(
            sala_id_valido, curso_id_valido3, materia_id_valido, professor_id_valido,
            dia_teste, 'Segunda Aula', 3
        );
        RAISE NOTICE '✅ TESTE 5 PASSOU: Aula em horário diferente criada com ID %', agendamento_id3;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ TESTE 5 FALHOU: %', SQLERRM;
    END;
    
    -- TESTE 6: Criar terceira aula no segundo horário (deve funcionar)
    RAISE NOTICE '--- TESTE 6: Criar terceira aula no segundo horário ---';
    BEGIN
        agendamento_id3 := criar_agendamento_teste(
            sala_id_valido, curso_id_valido1, materia_id_valido, professor_id_valido,
            dia_teste, 'Segunda Aula', 1
        );
        RAISE NOTICE '✅ TESTE 6 PASSOU: Terceira aula criada com ID %', agendamento_id3;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ TESTE 6 FALHOU: %', SQLERRM;
    END;
    
    -- TESTE 7: Criar quarta aula no segundo horário (deve funcionar)
    RAISE NOTICE '--- TESTE 7: Criar quarta aula no segundo horário ---';
    BEGIN
        agendamento_id3 := criar_agendamento_teste(
            sala_id_valido, curso_id_valido2, materia_id_valido, professor_id_valido,
            dia_teste, 'Segunda Aula', 2
        );
        RAISE NOTICE '✅ TESTE 7 PASSOU: Quarta aula criada com ID %', agendamento_id3;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ TESTE 7 FALHOU: %', SQLERRM;
    END;
    
    -- TESTE 8: Tentar criar quinta aula no período (deve falhar - limite de 4 por período)
    RAISE NOTICE '--- TESTE 8: Tentar criar quinta aula no período ---';
    BEGIN
        agendamento_id3 := criar_agendamento_teste(
            sala_id_valido, curso_id_valido3, materia_id_valido, professor_id_valido,
            dia_teste, 'Primeira Aula', 3
        );
        RAISE NOTICE '❌ TESTE 8 FALHOU: Quinta aula foi criada (não deveria) com ID %', agendamento_id3;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '✅ TESTE 8 PASSOU: Falhou corretamente - %', SQLERRM;
    END;
    
    -- Verificar resultado final
    RAISE NOTICE '--- RESULTADO FINAL ---';
    RAISE NOTICE 'Total de agendamentos criados para o dia de teste: %', 
                 (SELECT COUNT(*) FROM agendamento WHERE dia = dia_teste AND sala_id = sala_id_valido);
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ ERRO GERAL NOS TESTES: %', SQLERRM;
END $$;

-- 5. Verificar resultado dos testes
SELECT 
    'Resultado dos Testes' as info,
    COUNT(*) as total_agendamentos,
    COUNT(CASE WHEN aula_periodo = 'Primeira Aula' THEN 1 END) as aulas_primeira_aula,
    COUNT(CASE WHEN aula_periodo = 'Segunda Aula' THEN 1 END) as aulas_segunda_aula,
    COUNT(DISTINCT curso_id) as cursos_diferentes
FROM agendamento 
WHERE dia = (CURRENT_DATE + INTERVAL '1 day')::date;

-- 6. Mostrar detalhes dos agendamentos criados
SELECT 
    'Detalhes dos Agendamentos' as info,
    id,
    curso_id,
    aula_periodo,
    tipo_agendamento,
    dia
FROM agendamento 
WHERE dia = (CURRENT_DATE + INTERVAL '1 day')::date
ORDER BY aula_periodo, curso_id;

-- 7. Limpar dados de teste
DELETE FROM agendamento WHERE dia = (CURRENT_DATE + INTERVAL '1 day')::date;

-- 8. Verificar se a limpeza funcionou
SELECT 
    'Limpeza dos Testes' as info,
    COUNT(*) as agendamentos_restantes,
    'Deve ser 0' as observacao
FROM agendamento 
WHERE dia = (CURRENT_DATE + INTERVAL '1 day')::date; 