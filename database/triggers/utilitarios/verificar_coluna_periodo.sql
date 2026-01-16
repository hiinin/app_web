-- Script para verificar a coluna periodo na tabela agendamento
-- Execute este script para entender como a coluna periodo funciona

-- 1. Verificar se a coluna periodo existe e seus valores
SELECT 
    'Verificação da Coluna Período' as info,
    'Existe' as status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'agendamento' 
              AND column_name = 'periodo'
        ) THEN 'SIM'
        ELSE 'NÃO'
    END as resultado
UNION ALL
SELECT 
    'Verificação da Coluna Período' as info,
    'Tipo de Dados' as status,
    data_type
FROM information_schema.columns 
WHERE table_name = 'agendamento' 
  AND column_name = 'periodo'
UNION ALL
SELECT 
    'Verificação da Coluna Período' as info,
    'Permite NULL' as status,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'agendamento' 
  AND column_name = 'periodo';

-- 2. Verificar valores únicos na coluna periodo
SELECT 
    'Valores Únicos na Coluna Período' as info,
    periodo,
    COUNT(*) as quantidade
FROM agendamento 
WHERE periodo IS NOT NULL
GROUP BY periodo
ORDER BY periodo;

-- 3. Verificar registros onde periodo é NULL
SELECT 
    'Registros com Período NULL' as info,
    COUNT(*) as quantidade
FROM agendamento 
WHERE periodo IS NULL;

-- 4. Verificar se há conflitos de horário considerando apenas sala, dia e aula_periodo
SELECT 
    'Possíveis Conflitos de Horário (sem período)' as info,
    sala_id,
    dia,
    aula_periodo,
    COUNT(*) as quantidade_agendamentos
FROM agendamento 
GROUP BY sala_id, dia, aula_periodo
HAVING COUNT(*) > 1
ORDER BY quantidade_agendamentos DESC
LIMIT 10;

-- 5. Verificar se há conflitos de horário considerando período também
SELECT 
    'Possíveis Conflitos de Horário (com período)' as info,
    sala_id,
    dia,
    periodo,
    aula_periodo,
    COUNT(*) as quantidade_agendamentos
FROM agendamento 
WHERE periodo IS NOT NULL
GROUP BY sala_id, dia, periodo, aula_periodo
HAVING COUNT(*) > 1
ORDER BY quantidade_agendamentos DESC
LIMIT 10;

-- 6. Verificar se a função atual está funcionando
-- Vamos ver a função atual
SELECT 
    'Função Atual' as info,
    proname as nome_funcao,
    prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- 7. Criar uma versão da função que funciona com ou sem período
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
    
    -- Verificar conflito de horário (versão flexível)
    IF NEW.periodo IS NOT NULL THEN
        -- Se período foi fornecido, verificar conflito com período
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
    ELSE
        -- Se período não foi fornecido, verificar conflito sem período
        IF EXISTS (
            SELECT 1 FROM agendamento 
            WHERE sala_id = NEW.sala_id 
              AND dia = NEW.dia 
              AND aula_periodo = NEW.aula_periodo
              AND id != COALESCE(NEW.id, 0)
        ) THEN
            RAISE EXCEPTION 'Já existe um agendamento para esta sala, dia e aula';
        END IF;
    END IF;
    
    -- Verificar se o professor está associado à turma (curso) através de professor_turmas
    IF NEW.professor_id IS NOT NULL AND NEW.curso_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM professor_turmas 
            WHERE professor_id = NEW.professor_id 
              AND curso_id = NEW.curso_id
        ) THEN
            RAISE EXCEPTION 'Professor com ID % não está associado à turma (curso) com ID %', NEW.professor_id, NEW.curso_id;
        END IF;
    END IF;
    
    -- Se chegou até aqui, tudo está ok
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Testar a função atualizada
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    
    -- Testar inserção sem período
    INSERT INTO agendamento (
        aula_periodo, 
        sala_id, 
        curso_id, 
        materia_id, 
        dia, 
        tipo_agendamento
    ) VALUES (
        'Teste Sem Período', 
        sala_id_valido, 
        curso_id_valido, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '3 days')::date, 
        'T'
    );
    
    RAISE NOTICE 'Teste sem período realizado com sucesso!';
    
    -- Testar inserção com período
    INSERT INTO agendamento (
        aula_periodo, 
        sala_id, 
        curso_id, 
        materia_id, 
        dia, 
        periodo,
        tipo_agendamento
    ) VALUES (
        'Teste Com Período', 
        sala_id_valido, 
        curso_id_valido, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '4 days')::date, 
        1,
        'T'
    );
    
    RAISE NOTICE 'Teste com período realizado com sucesso!';
    
    -- Limpar os testes
    DELETE FROM agendamento WHERE tipo_agendamento = 'T';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;

-- 9. Verificar se o histórico foi criado
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