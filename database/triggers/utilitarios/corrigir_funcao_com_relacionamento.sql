-- Script para corrigir a função usando a tabela professor_materias
-- Execute este script para resolver os erros

-- 1. Primeiro, vamos verificar a estrutura da tabela professor_materias
SELECT 
    'Estrutura da Tabela Professor_Matérias' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'professor_materias'
ORDER BY ordinal_position;

-- 2. Verificar dados de exemplo na tabela professor_materias
SELECT 
    'Dados de Exemplo - Professor_Matérias' as info,
    *
FROM professor_materias 
LIMIT 10;

-- 3. Criar uma versão corrigida da função que usa a tabela professor_materias
CREATE OR REPLACE FUNCTION definir_horarios_agendamento()
RETURNS TRIGGER AS $$
BEGIN
    -- Validações básicas
    
    -- Verificar se a matéria existe
    IF NEW.materia_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM materias WHERE id = NEW.materia_id) THEN
        RAISE EXCEPTION 'Matéria com ID % não encontrada', NEW.materia_id;
    END IF;
    
    -- Verificar se a sala existe
    IF NOT EXISTS (SELECT 1 FROM salas WHERE id = NEW.sala_id) THEN
        RAISE EXCEPTION 'Sala com ID % não encontrada', NEW.sala_id;
    END IF;
    
    -- Verificar se o curso existe
    IF NOT EXISTS (SELECT 1 FROM cursos WHERE id = NEW.curso_id) THEN
        RAISE EXCEPTION 'Curso com ID % não encontrado', NEW.curso_id;
    END IF;
    
    -- Verificar se o professor existe (se fornecido)
    IF NEW.professor_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM professores WHERE id = NEW.professor_id) THEN
        RAISE EXCEPTION 'Professor com ID % não encontrado', NEW.professor_id;
    END IF;
    
    -- Verificar se a data não é no passado
    IF NEW.dia::date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Não é possível agendar para datas passadas';
    END IF;
    
    -- Verificar se não há conflito de horário na mesma sala, dia e período
    IF EXISTS (
        SELECT 1 FROM agendamento 
        WHERE sala_id = NEW.sala_id 
          AND dia = NEW.dia 
          AND periodo = NEW.periodo
          AND aula_periodo = NEW.aula_periodo
          AND id != COALESCE(NEW.id, 0)
    ) THEN
        RAISE EXCEPTION 'Já existe um agendamento para esta sala, dia, período e aula';
    END IF;
    
    -- Verificar se o professor está associado à matéria (se ambos forem fornecidos)
    IF NEW.professor_id IS NOT NULL AND NEW.materia_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM professor_materias 
            WHERE professor_id = NEW.professor_id 
              AND materia_id = NEW.materia_id
        ) THEN
            RAISE EXCEPTION 'Professor com ID % não está associado à matéria com ID %', NEW.professor_id, NEW.materia_id;
        END IF;
    END IF;
    
    -- Se chegou até aqui, tudo está ok
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Verificar se a função foi atualizada
SELECT 
    'Função Atualizada' as info,
    proname as nome_funcao,
    prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- 5. Verificar se há triggers usando esta função
SELECT 
    'Triggers que usam a função' as info,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE action_statement LIKE '%definir_horarios_agendamento%'
ORDER BY trigger_name;

-- 6. Testar se a função funciona agora
-- Primeiro, vamos verificar se existem dados válidos
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
FROM professores
UNION ALL
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Professor_Matérias' as tipo,
    COUNT(*) as quantidade
FROM professor_materias;

-- 7. Pegar IDs válidos para o teste
SELECT 
    'IDs Válidos para Teste' as info,
    'Matéria' as tipo,
    MIN(id) as id_minimo
FROM materias
UNION ALL
SELECT 
    'IDs Válidos para Teste' as info,
    'Sala' as tipo,
    MIN(id) as id_minimo
FROM salas
UNION ALL
SELECT 
    'IDs Válidos para Teste' as info,
    'Curso' as tipo,
    MIN(id) as id_minimo
FROM cursos
UNION ALL
SELECT 
    'IDs Válidos para Teste' as info,
    'Professor' as tipo,
    MIN(id) as id_minimo
FROM professores;

-- 8. Pegar uma associação válida professor-matéria
SELECT 
    'Associação Professor-Matéria Válida' as info,
    pm.professor_id,
    p.nome_professor,
    pm.materia_id,
    m.nome as nome_materia
FROM professor_materias pm
JOIN professores p ON pm.professor_id = p.id
JOIN materias m ON pm.materia_id = m.id
LIMIT 5;

-- 9. Testar a função com dados válidos
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
    professor_id_valido INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    SELECT MIN(id) INTO professor_id_valido FROM professores;
    
    -- Se não houver dados, criar alguns para teste
    IF materia_id_valido IS NULL THEN
        INSERT INTO materias (nome, curso_id) VALUES ('Matemática', curso_id_valido) RETURNING id INTO materia_id_valido;
    END IF;
    
    IF sala_id_valido IS NULL THEN
        INSERT INTO salas (numero_sala) VALUES ('101') RETURNING id INTO sala_id_valido;
    END IF;
    
    IF curso_id_valido IS NULL THEN
        INSERT INTO cursos (nome, periodo) VALUES ('Informática', 1) RETURNING id INTO curso_id_valido;
    END IF;
    
    IF professor_id_valido IS NULL THEN
        INSERT INTO professores (nome_professor) VALUES ('Professor Teste') RETURNING id INTO professor_id_valido;
    END IF;
    
    -- Criar associação professor-matéria se não existir
    IF NOT EXISTS (SELECT 1 FROM professor_materias WHERE professor_id = professor_id_valido AND materia_id = materia_id_valido) THEN
        INSERT INTO professor_materias (professor_id, materia_id) VALUES (professor_id_valido, materia_id_valido);
    END IF;
    
    -- Testar inserção sem professor (deve funcionar)
    INSERT INTO agendamento (
        aula_periodo, 
        sala_id, 
        curso_id, 
        materia_id, 
        dia, 
        periodo, 
        tipo_agendamento
    ) VALUES (
        'Teste Função Sem Professor', 
        sala_id_valido, 
        curso_id_valido, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '1 day')::date, 
        1, 
        'T'
    );
    
    RAISE NOTICE 'Teste sem professor realizado com sucesso!';
    
    -- Testar inserção com professor (deve funcionar)
    INSERT INTO agendamento (
        aula_periodo, 
        sala_id, 
        curso_id, 
        materia_id, 
        professor_id,
        dia, 
        periodo, 
        tipo_agendamento
    ) VALUES (
        'Teste Função Com Professor', 
        sala_id_valido, 
        curso_id_valido, 
        materia_id_valido, 
        professor_id_valido,
        (CURRENT_DATE + INTERVAL '2 days')::date, 
        1, 
        'T'
    );
    
    RAISE NOTICE 'Teste com professor realizado com sucesso!';
    
    -- Limpar os testes
    DELETE FROM agendamento WHERE tipo_agendamento = 'T';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;

-- 10. Verificar se o histórico foi criado
SELECT 
    'Histórico de Teste' as info,
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