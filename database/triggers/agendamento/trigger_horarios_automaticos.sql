-- Trigger para definir automaticamente os horários baseados no período do curso
-- Execute este script no Supabase SQL Editor

-- 1. Primeiro, vamos criar a função que define os horários
CREATE OR REPLACE FUNCTION definir_horarios_automaticos()
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
    
    -- Define os horários no registro
    NEW.hora_inicio := hora_inicio_val;
    NEW.hora_fim := hora_fim_val;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Criar o trigger que executa antes do INSERT
DROP TRIGGER IF EXISTS trigger_definir_horarios ON agendamento;

CREATE TRIGGER trigger_definir_horarios
    BEFORE INSERT ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION definir_horarios_automaticos();

-- 3. Verificar se o trigger foi criado
SELECT 
    'Trigger Criado' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_definir_horarios'
ORDER BY trigger_name;

-- 4. Testar o trigger com dados de exemplo
DO $$
DECLARE
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
        INSERT INTO cursos (nome, periodo) VALUES ('Curso Matutino Teste', 1) RETURNING id INTO curso_matutino_id;
    END IF;
    
    IF curso_vespertino_id IS NULL THEN
        INSERT INTO cursos (nome, periodo) VALUES ('Curso Vespertino Teste', 2) RETURNING id INTO curso_vespertino_id;
    END IF;
    
    IF curso_noturno_id IS NULL THEN
        INSERT INTO cursos (nome, periodo) VALUES ('Curso Noturno Teste', 3) RETURNING id INTO curso_noturno_id;
    END IF;
    
    -- Testar inserção com curso matutino
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
        curso_matutino_id, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '1 day')::date, 
        1, 
        'T'
    );
    
    RAISE NOTICE 'Teste Matutino - Primeira Aula realizado!';
    
    -- Testar inserção com curso vespertino
    INSERT INTO agendamento (
        aula_periodo, 
        sala_id, 
        curso_id, 
        materia_id, 
        dia, 
        periodo, 
        tipo_agendamento
    ) VALUES (
        'Segunda Aula', 
        sala_id_valido, 
        curso_vespertino_id, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '2 days')::date, 
        2, 
        'T'
    );
    
    RAISE NOTICE 'Teste Vespertino - Segunda Aula realizado!';
    
    -- Testar inserção com curso noturno
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
        curso_noturno_id, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '3 days')::date, 
        3, 
        'T'
    );
    
    RAISE NOTICE 'Teste Noturno - Primeira Aula realizado!';
    
    -- Limpar os testes
    DELETE FROM agendamento WHERE tipo_agendamento = 'T';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;

-- 5. Verificar os horários definidos automaticamente
SELECT 
    'Horários Definidos Automaticamente' as info,
    a.id,
    a.aula_periodo,
    c.nome as curso,
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
    'Resumo dos Horários por Período' as info,
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