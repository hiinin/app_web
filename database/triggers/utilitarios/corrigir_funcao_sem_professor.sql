-- Script para corrigir a função sem depender de relacionamento professor-matéria
-- Execute este script para resolver os erros

-- 1. Primeiro, vamos ver a função atual
SELECT 
    'Função Atual' as info,
    proname as nome_funcao,
    prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- 2. Criar uma versão simplificada da função que não exige professor
CREATE OR REPLACE FUNCTION definir_horarios_agendamento()
RETURNS TRIGGER AS $$
BEGIN
    -- Validações básicas sem depender de relacionamento professor-matéria
    
    -- Verificar se a matéria existe
    IF NOT EXISTS (SELECT 1 FROM materias WHERE id = NEW.materia_id) THEN
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
    
    -- Se chegou até aqui, tudo está ok
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Verificar se a função foi atualizada
SELECT 
    'Função Atualizada' as info,
    proname as nome_funcao,
    prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- 4. Verificar se há triggers usando esta função
SELECT 
    'Triggers que usam a função' as info,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE action_statement LIKE '%definir_horarios_agendamento%'
ORDER BY trigger_name;

-- 5. Testar se a função funciona agora
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
FROM cursos;

-- 6. Pegar IDs válidos para o teste
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
FROM cursos;

-- 7. Testar a função com dados válidos
DO $$
DECLARE
    materia_id_valido INTEGER;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    
    -- Se não houver dados, criar alguns para teste
    IF materia_id_valido IS NULL THEN
        INSERT INTO materias (nome) VALUES ('Matemática') RETURNING id INTO materia_id_valido;
    END IF;
    
    IF sala_id_valido IS NULL THEN
        INSERT INTO salas (numero_sala) VALUES ('101') RETURNING id INTO sala_id_valido;
    END IF;
    
    IF curso_id_valido IS NULL THEN
        INSERT INTO cursos (nome, periodo) VALUES ('Informática', 1) RETURNING id INTO curso_id_valido;
    END IF;
    
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
        'Teste Função', 
        sala_id_valido, 
        curso_id_valido, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '1 day')::date, 
        1, 
        'T'
    );
    
    RAISE NOTICE 'Teste realizado com sucesso!';
    
    -- Limpar o teste
    DELETE FROM agendamento WHERE tipo_agendamento = 'T';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;

-- 8. Verificar se o histórico foi criado
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