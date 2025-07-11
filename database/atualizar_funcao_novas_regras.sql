-- Atualização da função definir_horarios_agendamento com as novas regras de negócio
-- Execute este script no Supabase SQL Editor

-- Primeiro, vamos criar uma função auxiliar para contar alocações por sala por dia
CREATE OR REPLACE FUNCTION contar_alocacoes_sala_dia(
    p_sala_id INTEGER,
    p_dia DATE,
    p_agendamento_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    total_alocacoes INTEGER;
BEGIN
    -- Conta quantas vezes a sala foi alocada na data específica
    SELECT COUNT(*) INTO total_alocacoes
    FROM agendamento 
    WHERE sala_id = p_sala_id 
      AND dia = p_dia
      AND id != COALESCE(p_agendamento_id, 0);
    
    RETURN total_alocacoes;
END;
$$ LANGUAGE plpgsql;

-- Função auxiliar para contar cursos no mesmo horário
CREATE OR REPLACE FUNCTION contar_cursos_mesmo_horario(
    p_sala_id INTEGER,
    p_dia DATE,
    p_periodo INTEGER,
    p_aula_periodo TEXT,
    p_agendamento_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    total_cursos INTEGER;
BEGIN
    -- Conta quantos cursos diferentes estão alocados no mesmo horário
    SELECT COUNT(DISTINCT curso_id) INTO total_cursos
    FROM agendamento 
    WHERE sala_id = p_sala_id 
      AND dia = p_dia
      AND periodo = p_periodo
      AND aula_periodo = p_aula_periodo
      AND id != COALESCE(p_agendamento_id, 0);
    
    RETURN total_cursos;
END;
$$ LANGUAGE plpgsql;

-- Função auxiliar para verificar se o curso já está alocado no mesmo horário
CREATE OR REPLACE FUNCTION curso_ja_alocado_horario(
    p_sala_id INTEGER,
    p_dia DATE,
    p_periodo INTEGER,
    p_aula_periodo TEXT,
    p_curso_id INTEGER,
    p_agendamento_id INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    ja_alocado BOOLEAN;
BEGIN
    -- Verifica se o curso já está alocado no mesmo horário
    SELECT EXISTS(
        SELECT 1 FROM agendamento 
        WHERE sala_id = p_sala_id 
          AND dia = p_dia
          AND periodo = p_periodo
          AND aula_periodo = p_aula_periodo
          AND curso_id = p_curso_id
          AND id != COALESCE(p_agendamento_id, 0)
    ) INTO ja_alocado;
    
    RETURN ja_alocado;
END;
$$ LANGUAGE plpgsql;

-- Nova versão da função principal com as regras atualizadas
CREATE OR REPLACE FUNCTION definir_horarios_agendamento()
RETURNS TRIGGER AS $$
DECLARE
    total_alocacoes_dia INTEGER;
    total_cursos_horario INTEGER;
    curso_ja_alocado BOOLEAN;
    periodo_curso INTEGER;
    hora_inicio_val TIME;
    hora_fim_val TIME;
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
    
    -- NOVAS REGRAS DE NEGÓCIO
    
    -- 1. Verificar limite total de alocações por dia (máximo 12)
    total_alocacoes_dia := contar_alocacoes_sala_dia(NEW.sala_id, NEW.dia, NEW.id);
    
    IF total_alocacoes_dia >= 12 THEN
        RAISE EXCEPTION 'Sala já atingiu o limite máximo de 12 alocações para o dia %', NEW.dia;
    END IF;
    
    -- 2. Verificar regras específicas por tipo de agendamento
    IF NEW.tipo_agendamento = 'A' THEN -- AULA
        -- Para aulas: máximo 2 cursos no mesmo horário
        total_cursos_horario := contar_cursos_mesmo_horario(NEW.sala_id, NEW.dia, NEW.periodo, NEW.aula_periodo, NEW.id);
        
        IF total_cursos_horario >= 2 THEN
            RAISE EXCEPTION 'Já existem 2 cursos alocados para esta sala, dia, período e horário';
        END IF;
        
        -- Verificar se o curso já está alocado no mesmo horário
        curso_ja_alocado := curso_ja_alocado_horario(NEW.sala_id, NEW.dia, NEW.periodo, NEW.aula_periodo, NEW.curso_id, NEW.id);
        
        IF curso_ja_alocado THEN
            RAISE EXCEPTION 'Este curso já está alocado para esta sala, dia, período e horário';
        END IF;
        
    ELSIF NEW.tipo_agendamento = 'M' THEN -- PROVA
        -- Para provas: manter regra antiga (1 curso por horário)
        IF EXISTS (
            SELECT 1 FROM agendamento 
            WHERE sala_id = NEW.sala_id 
              AND dia = NEW.dia 
              AND periodo = NEW.periodo
              AND aula_periodo = NEW.aula_periodo
              AND id != COALESCE(NEW.id, 0)
        ) THEN
            RAISE EXCEPTION 'Já existe um agendamento para esta sala, dia, período e horário';
        END IF;
        
    ELSIF NEW.tipo_agendamento = 'E' THEN -- EVENTO
        -- Para eventos: permitir múltiplos cursos (sem restrição de conflito)
        -- Apenas verificar o limite total de 12 alocações por dia (já verificado acima)
        NULL; -- Não há validação adicional para eventos
        
    ELSE
        RAISE EXCEPTION 'Tipo de agendamento inválido: %', NEW.tipo_agendamento;
    END IF;
    
    -- Definir horários automaticamente
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

-- Comentários sobre as novas regras implementadas
COMMENT ON FUNCTION definir_horarios_agendamento() IS '
NOVAS REGRAS DE NEGÓCIO IMPLEMENTADAS:

1. LIMITE TOTAL: Máximo 12 alocações por sala por dia
2. AULAS: Máximo 2 cursos diferentes no mesmo horário
3. PROVAS: Mantém regra antiga (1 curso por horário)
4. EVENTOS: Permite múltiplos cursos sem restrição de conflito

VALIDAÇÕES:
- Verifica se sala não excedeu limite de 12 alocações/dia
- Para aulas: verifica se não há mais de 2 cursos no mesmo horário
- Para aulas: verifica se o curso não está duplicado no mesmo horário
- Para provas: mantém validação de conflito único
- Para eventos: apenas verifica limite total de 12 alocações
'; 