-- =====================================================
-- SCRIPT: Corrigir função definir_horarios_agendamento para usar professor_turmas
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- PASSO 1: Verificar a função atual
SELECT 
    'Função Atual' as info,
    proname as nome_funcao,
    prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- PASSO 2: Atualizar a função para usar professor_turmas em vez de professor_materias
-- Primeiro, vamos verificar se a função existe e obter sua definição completa
DO $$
DECLARE
    func_def TEXT;
BEGIN
    -- Busca a definição atual da função
    SELECT prosrc INTO func_def
    FROM pg_proc
    WHERE proname = 'definir_horarios_agendamento'
    LIMIT 1;
    
    IF func_def IS NOT NULL THEN
        -- Se a função contém referência a professor_materias, precisa ser atualizada
        IF func_def LIKE '%professor_materias%' THEN
            RAISE NOTICE 'Função contém referência a professor_materias - precisa ser atualizada';
        ELSE
            RAISE NOTICE 'Função não contém referência a professor_materias';
        END IF;
    ELSE
        RAISE NOTICE 'Função definir_horarios_agendamento não encontrada';
    END IF;
END $$;

-- PASSO 3: Criar/Atualizar função corrigida
-- Esta é uma versão básica que remove a validação de professor_materias
-- Se você tiver uma função mais complexa, ajuste conforme necessário
CREATE OR REPLACE FUNCTION definir_horarios_agendamento()
RETURNS TRIGGER AS $$
DECLARE
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
    
    -- NOVA VALIDAÇÃO: Verificar se o professor está associado à turma (curso) através de professor_turmas
    IF NEW.professor_id IS NOT NULL AND NEW.curso_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM professor_turmas 
            WHERE professor_id = NEW.professor_id 
              AND curso_id = NEW.curso_id
        ) THEN
            RAISE EXCEPTION 'Professor com ID % não está associado à turma (curso) com ID %', NEW.professor_id, NEW.curso_id;
        END IF;
    END IF;
    
    -- Define os horários baseados no período do curso e período da aula
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
    
    -- Atualiza os horários no registro
    NEW.hora_inicio := hora_inicio_val;
    NEW.hora_fim := hora_fim_val;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASSO 4: Verificar se o trigger está usando a função correta
SELECT 
    'Triggers que usam definir_horarios_agendamento' as info,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE action_statement LIKE '%definir_horarios_agendamento%'
ORDER BY event_object_table, trigger_name;

-- PASSO 5: Verificar se a função foi atualizada corretamente
SELECT 
    'Função Atualizada' as info,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%professor_materias%' THEN '❌ Ainda contém professor_materias'
        WHEN prosrc LIKE '%professor_turmas%' THEN '✅ Usa professor_turmas'
        ELSE '⚠️ Não verifica vínculo professor-turma'
    END as status
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';






