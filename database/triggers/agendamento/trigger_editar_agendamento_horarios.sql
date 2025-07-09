-- Trigger específico para edição de agendamentos
-- Este trigger SEMPRE atualiza os horários quando um agendamento é editado
-- Execute este script no Supabase SQL Editor

-- 1. Criar função específica para edição que sempre atualiza horários
CREATE OR REPLACE FUNCTION atualizar_horarios_na_edicao()
RETURNS TRIGGER AS $$
DECLARE
    periodo_curso INTEGER;
    hora_inicio_val TIME;
    hora_fim_val TIME;
BEGIN
    -- Pega o período do curso
    SELECT periodo INTO periodo_curso 
    FROM cursos 
    WHERE id = NEW.curso_id;
    
    -- Define os horários baseados no período da aula e período do curso
    CASE 
        -- PRIMEIRA AULA
        WHEN NEW.aula_periodo = 'Primeira Aula' THEN
            CASE periodo_curso
                WHEN 1 THEN -- Matutino
                    hora_inicio_val := '07:00:00';
                    hora_fim_val := '08:40:00';
                WHEN 2 THEN -- Vespertino
                    hora_inicio_val := '13:00:00';
                    hora_fim_val := '14:40:00';
                WHEN 3 THEN -- Noturno
                    hora_inicio_val := '19:00:00';
                    hora_fim_val := '20:40:00';
                ELSE
                    hora_inicio_val := '08:00:00';
                    hora_fim_val := '09:00:00';
            END CASE;
            
        -- SEGUNDA AULA
        WHEN NEW.aula_periodo = 'Segunda Aula' THEN
            CASE periodo_curso
                WHEN 1 THEN -- Matutino
                    hora_inicio_val := '08:55:00';
                    hora_fim_val := '10:35:00';
                WHEN 2 THEN -- Vespertino
                    hora_inicio_val := '14:55:00';
                    hora_fim_val := '16:35:00';
                WHEN 3 THEN -- Noturno
                    hora_inicio_val := '20:55:00';
                    hora_fim_val := '22:35:00';
                ELSE
                    hora_inicio_val := '09:00:00';
                    hora_fim_val := '10:00:00';
            END CASE;
            
        -- Para outros períodos, usar horário padrão
        ELSE
            hora_inicio_val := '08:00:00';
            hora_fim_val := '09:00:00';
    END CASE;
    
    -- SEMPRE define os horários no registro (independente de como foi criado)
    NEW.hora_inicio := hora_inicio_val;
    NEW.hora_fim := hora_fim_val;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Criar o trigger específico para edição
DROP TRIGGER IF EXISTS trigger_editar_agendamento_horarios ON agendamento;

CREATE TRIGGER trigger_editar_agendamento_horarios
    BEFORE UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_horarios_na_edicao();

-- 3. Verificar se o trigger foi criado
SELECT 
    'Trigger de Edição Criado' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_editar_agendamento_horarios'
ORDER BY trigger_name;

-- 4. Testar o trigger com diferentes cenários
DO $$
DECLARE
    agendamento_teste_id INTEGER;
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_matutino_id INTEGER;
    curso_vespertino_id INTEGER;
    curso_noturno_id INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    
    -- Pegar cursos de diferentes períodos
    SELECT MIN(id) INTO curso_matutino_id FROM cursos WHERE periodo = 1;
    SELECT MIN(id) INTO curso_vespertino_id FROM cursos WHERE periodo = 2;
    SELECT MIN(id) INTO curso_noturno_id FROM cursos WHERE periodo = 3;
    
    -- Se não houver cursos com esses períodos, criar alguns para teste
    IF curso_matutino_id IS NULL THEN
        INSERT INTO cursos (curso, periodo) VALUES ('Curso Matutino Teste', 1) RETURNING id INTO curso_matutino_id;
    END IF;
    
    IF curso_vespertino_id IS NULL THEN
        INSERT INTO cursos (curso, periodo) VALUES ('Curso Vespertino Teste', 2) RETURNING id INTO curso_vespertino_id;
    END IF;
    
    IF curso_noturno_id IS NULL THEN
        INSERT INTO cursos (curso, periodo) VALUES ('Curso Noturno Teste', 3) RETURNING id INTO curso_noturno_id;
    END IF;
    
    -- Criar um agendamento de teste com horários manuais
    INSERT INTO agendamento (
        aula_periodo, 
        sala_id, 
        curso_id, 
        materia_id, 
        dia, 
        periodo, 
        tipo_agendamento,
        hora_inicio,
        hora_fim
    ) VALUES (
        'Primeira Aula', 
        sala_id_valido, 
        curso_matutino_id, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '1 day')::date, 
        1, 
        'T',
        '10:00:00', -- Horário manual diferente do padrão
        '11:00:00'  -- Horário manual diferente do padrão
    ) RETURNING id INTO agendamento_teste_id;
    
    RAISE NOTICE 'Agendamento de teste criado com ID: % e horários manuais', agendamento_teste_id;
    
    -- Testar UPDATE mudando apenas o curso (deve atualizar horários)
    UPDATE agendamento 
    SET curso_id = curso_vespertino_id
    WHERE id = agendamento_teste_id;
    
    RAISE NOTICE 'Teste UPDATE - Curso alterado para vespertino (horários devem ser atualizados)!';
    
    -- Testar UPDATE mudando apenas o período da aula (deve atualizar horários)
    UPDATE agendamento 
    SET aula_periodo = 'Segunda Aula'
    WHERE id = agendamento_teste_id;
    
    RAISE NOTICE 'Teste UPDATE - Período da aula alterado para Segunda Aula (horários devem ser atualizados)!';
    
    -- Testar UPDATE mudando sala (não deve afetar horários)
    UPDATE agendamento 
    SET sala_id = sala_id_valido
    WHERE id = agendamento_teste_id;
    
    RAISE NOTICE 'Teste UPDATE - Sala alterada (horários devem permanecer os mesmos)!';
    
    -- Limpar o teste
    DELETE FROM agendamento WHERE id = agendamento_teste_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;

-- 5. Verificar os horários definidos automaticamente
SELECT 
    'Horários Atualizados na Edição' as info,
    a.id,
    a.aula_periodo,
    c.curso,
    c.periodo,
    a.hora_inicio,
    a.hora_fim,
    a.dia
FROM agendamento a
JOIN cursos c ON a.curso_id = c.id
WHERE a.tipo_agendamento = 'T'
ORDER BY a.id DESC
LIMIT 10;

-- 6. Mostrar resumo dos horários por período
SELECT 
    'Resumo dos Horários por Período (Edição)' as info,
    CASE 
        WHEN c.periodo = 1 THEN 'MATUTINO'
        WHEN c.periodo = 2 THEN 'VESPERTINO'
        WHEN c.periodo = 3 THEN 'NOTURNO'
        ELSE 'DESCONHECIDO'
    END as periodo_curso,
    a.aula_periodo,
    a.hora_inicio,
    a.hora_fim
FROM agendamento a
JOIN cursos c ON a.curso_id = c.id
WHERE a.tipo_agendamento = 'T'
ORDER BY c.periodo, a.aula_periodo; 