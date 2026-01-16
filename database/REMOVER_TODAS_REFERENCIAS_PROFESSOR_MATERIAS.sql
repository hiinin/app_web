-- =====================================================
-- SCRIPT URGENTE: Remover TODAS as referências a professor_materias
-- Execute este script no Supabase SQL Editor IMEDIATAMENTE
-- =====================================================

-- PASSO 1: Listar TODAS as funções que referenciam professor_materias
SELECT 
    '🔍 Funções que referenciam professor_materias' as info,
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines
WHERE routine_definition LIKE '%professor_materias%'
  AND routine_schema = 'public';

-- PASSO 2: Listar TODOS os triggers que referenciam professor_materias
SELECT 
    '🔍 Triggers que referenciam professor_materias' as info,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE action_statement LIKE '%professor_materias%'
  AND trigger_schema = 'public';

-- PASSO 3: DESABILITAR temporariamente TODOS os triggers da tabela agendamento
-- (para evitar erros durante a correção)
ALTER TABLE agendamento DISABLE TRIGGER ALL;

-- PASSO 4: Remover TODOS os triggers que referenciam professor_materias
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT DISTINCT trigger_name, event_object_table
        FROM information_schema.triggers
        WHERE action_statement LIKE '%professor_materias%'
          AND trigger_schema = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I CASCADE', 
                trigger_record.trigger_name, 
                trigger_record.event_object_table);
            RAISE NOTICE '✅ Trigger removido: % da tabela %', 
                trigger_record.trigger_name, 
                trigger_record.event_object_table;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Erro ao remover trigger %: %', 
                trigger_record.trigger_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- PASSO 5: Remover TODAS as funções que referenciam professor_materias
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT DISTINCT routine_name
        FROM information_schema.routines
        WHERE routine_definition LIKE '%professor_materias%'
          AND routine_schema = 'public'
          AND routine_type = 'FUNCTION'
    LOOP
        BEGIN
            EXECUTE format('DROP FUNCTION IF EXISTS %I CASCADE', func_record.routine_name);
            RAISE NOTICE '✅ Função removida: %', func_record.routine_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Erro ao remover função %: %', 
                func_record.routine_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- PASSO 6: Recriar a função definir_horarios_agendamento SEM referências a professor_materias
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
    
    -- ✅ NOVA VALIDAÇÃO: Verificar se o professor está associado à turma (curso) através de professor_turmas
    IF NEW.professor_id IS NOT NULL AND NEW.curso_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM professor_turmas 
            WHERE professor_id = NEW.professor_id 
              AND curso_id = NEW.curso_id
        ) THEN
            RAISE EXCEPTION 'Professor com ID % não está associado à turma (curso) com ID %', NEW.professor_id, NEW.curso_id;
        END IF;
    END IF;
    
    -- NOVAS REGRAS DE NEGÓCIO
    
    -- 1. Verificar limite total de alocações por dia (máximo 12)
    SELECT COUNT(*) INTO total_alocacoes_dia
    FROM agendamento 
    WHERE sala_id = NEW.sala_id 
      AND dia = NEW.dia
      AND id != COALESCE(NEW.id, 0);
    
    IF total_alocacoes_dia >= 12 THEN
        RAISE EXCEPTION 'Sala já atingiu o limite máximo de 12 alocações para o dia %', NEW.dia;
    END IF;
    
    -- 2. Verificar regras específicas por tipo de agendamento
    IF NEW.tipo_agendamento = 'A' THEN -- AULA
        -- Para aulas: máximo 2 cursos no mesmo horário
        SELECT COUNT(DISTINCT curso_id) INTO total_cursos_horario
        FROM agendamento 
        WHERE sala_id = NEW.sala_id 
          AND dia = NEW.dia
          AND periodo = NEW.periodo
          AND aula_periodo = NEW.aula_periodo
          AND id != COALESCE(NEW.id, 0);
        
        IF total_cursos_horario >= 2 THEN
            RAISE EXCEPTION 'Já existem 2 cursos alocados para esta sala, dia, período e horário';
        END IF;
        
        -- Verificar se o curso já está alocado no mesmo horário
        SELECT EXISTS(
            SELECT 1 FROM agendamento 
            WHERE sala_id = NEW.sala_id 
              AND dia = NEW.dia
              AND periodo = NEW.periodo
              AND aula_periodo = NEW.aula_periodo
              AND curso_id = NEW.curso_id
              AND id != COALESCE(NEW.id, 0)
        ) INTO curso_ja_alocado;
        
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

-- PASSO 7: Recriar o trigger na tabela agendamento
DROP TRIGGER IF EXISTS trigger_definir_horarios_agendamento ON agendamento;

CREATE TRIGGER trigger_definir_horarios_agendamento
    BEFORE INSERT OR UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION definir_horarios_agendamento();

-- PASSO 8: REABILITAR os triggers da tabela agendamento
ALTER TABLE agendamento ENABLE TRIGGER ALL;

-- PASSO 9: Verificar se ainda há referências a professor_materias
SELECT 
    '✅ Verificação Final - Funções' as info,
    COUNT(*) as quantidade_referencias
FROM information_schema.routines
WHERE routine_definition LIKE '%professor_materias%'
  AND routine_schema = 'public'
UNION ALL
SELECT 
    '✅ Verificação Final - Triggers' as info,
    COUNT(*) as quantidade_referencias
FROM information_schema.triggers
WHERE action_statement LIKE '%professor_materias%'
  AND trigger_schema = 'public';

-- PASSO 10: Verificar se a função foi criada corretamente
SELECT 
    '✅ Status da Função definir_horarios_agendamento' as info,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%professor_materias%' THEN '❌ AINDA CONTÉM professor_materias - ERRO!'
        WHEN prosrc LIKE '%professor_turmas%' THEN '✅ Usa professor_turmas corretamente'
        ELSE '⚠️ Não verifica vínculo professor-turma'
    END as status
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- PASSO 11: Verificar triggers ativos na tabela agendamento
SELECT 
    '✅ Triggers Ativos na Tabela agendamento' as info,
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






