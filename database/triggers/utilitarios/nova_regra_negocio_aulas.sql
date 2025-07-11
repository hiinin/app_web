-- Script para implementar as novas regras de negócio para aulas
-- Execute este script no Supabase SQL Editor

-- 1. Primeiro, vamos verificar a estrutura atual da tabela agendamento
SELECT 
    'Estrutura da Tabela Agendamento' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'agendamento'
ORDER BY ordinal_position;

-- 2. Verificar as regras atuais de validação
SELECT 
    'Regras Atuais' as info,
    'Limite por sala por dia: 6 agendamentos' as regra_1,
    'Limite por horário: 1 curso por horário' as regra_2,
    'Tipos: A=Aula, E=Evento, M=Prova' as regra_3;

-- 3. Criar uma nova função de validação para as aulas com as novas regras
CREATE OR REPLACE FUNCTION validar_agendamento_aula_nova_regra()
RETURNS TRIGGER AS $$
DECLARE
    total_agendamentos_sala_dia INTEGER;
    total_aulas_mesmo_horario INTEGER;
    total_cursos_mesmo_horario INTEGER;
BEGIN
    -- Validações básicas
    IF NEW.tipo_agendamento != 'A' THEN
        RETURN NEW; -- Não aplica validações específicas de aula para outros tipos
    END IF;
    
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
    
    -- Verificar se a data não é no passado
    IF NEW.dia::date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Não é possível agendar para datas passadas';
    END IF;
    
    -- NOVA REGRA 1: Verificar se a sala não excedeu o limite por período
    -- Cada período (matutino, vespertino, noturno) pode ter até 4 aulas (2 por horário)
    SELECT COUNT(*) INTO total_agendamentos_sala_dia
    FROM agendamento 
    WHERE sala_id = NEW.sala_id 
      AND dia = NEW.dia
      AND periodo = NEW.periodo
      AND id != COALESCE(NEW.id, 0);
    
    IF total_agendamentos_sala_dia >= 4 THEN
        RAISE EXCEPTION 'Sala já atingiu o limite de 4 agendamentos para o período % no dia %', 
                       CASE NEW.periodo 
                           WHEN 1 THEN 'Matutino'
                           WHEN 2 THEN 'Vespertino' 
                           WHEN 3 THEN 'Noturno'
                           ELSE 'Desconhecido'
                       END, NEW.dia;
    END IF;
    
    -- NOVA REGRA 2: Verificar se não há mais de 2 aulas no mesmo horário
    SELECT COUNT(*) INTO total_aulas_mesmo_horario
    FROM agendamento 
    WHERE sala_id = NEW.sala_id 
      AND dia = NEW.dia
      AND aula_periodo = NEW.aula_periodo
      AND tipo_agendamento = 'A'
      AND id != COALESCE(NEW.id, 0);
    
    IF total_aulas_mesmo_horario >= 2 THEN
        RAISE EXCEPTION 'Já existem 2 aulas agendadas para o horário "%" no dia %', NEW.aula_periodo, NEW.dia;
    END IF;
    
    -- NOVA REGRA 3: Verificar se não há mais de 2 cursos diferentes no mesmo horário
    SELECT COUNT(DISTINCT curso_id) INTO total_cursos_mesmo_horario
    FROM agendamento 
    WHERE sala_id = NEW.sala_id 
      AND dia = NEW.dia
      AND aula_periodo = NEW.aula_periodo
      AND id != COALESCE(NEW.id, 0);
    
    -- Se já existe um curso diferente no mesmo horário, verificar se o novo curso é diferente
    IF total_cursos_mesmo_horario >= 2 THEN
        RAISE EXCEPTION 'Já existem 2 cursos diferentes agendados para o horário "%" no dia %', NEW.aula_periodo, NEW.dia;
    ELSIF total_cursos_mesmo_horario = 1 THEN
        -- Verificar se o novo curso é diferente dos existentes
        IF EXISTS (
            SELECT 1 FROM agendamento 
            WHERE sala_id = NEW.sala_id 
              AND dia = NEW.dia
              AND aula_periodo = NEW.aula_periodo
              AND curso_id = NEW.curso_id
              AND id != COALESCE(NEW.id, 0)
        ) THEN
            RAISE EXCEPTION 'Este curso já está agendado para o horário "%" no dia %', NEW.aula_periodo, NEW.dia;
        END IF;
    END IF;
    
    -- Se chegou até aqui, tudo está ok
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Criar trigger para aplicar a nova validação
DROP TRIGGER IF EXISTS trigger_validar_aula_nova_regra ON agendamento;

CREATE TRIGGER trigger_validar_aula_nova_regra
    BEFORE INSERT OR UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION validar_agendamento_aula_nova_regra();

-- 5. Verificar se o trigger foi criado
SELECT 
    'Trigger Criado' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_validar_aula_nova_regra';

-- 6. Testar a nova função com dados de exemplo
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
    curso_id_valido2 INTEGER;
    professor_id_valido INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    SELECT MIN(id) INTO professor_id_valido FROM professores;
    
    -- Pegar um segundo curso diferente
    SELECT MIN(id) INTO curso_id_valido2 
    FROM cursos 
    WHERE id != curso_id_valido;
    
    -- Se não houver segundo curso, criar um
    IF curso_id_valido2 IS NULL THEN
        INSERT INTO cursos (curso, periodo) VALUES ('Curso Teste 2', 2) RETURNING id INTO curso_id_valido2;
    END IF;
    
    RAISE NOTICE 'Testando nova regra de negócio...';
    RAISE NOTICE 'Materia ID: %, Sala ID: %, Curso 1 ID: %, Curso 2 ID: %, Professor ID: %', 
                 materia_id_valido, sala_id_valido, curso_id_valido, curso_id_valido2, professor_id_valido;
    
    -- Teste 1: Criar primeira aula (deve funcionar)
    BEGIN
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
            'Primeira Aula', 
            sala_id_valido, 
            curso_id_valido, 
            materia_id_valido, 
            professor_id_valido,
            (CURRENT_DATE + INTERVAL '1 day')::date, 
            1, 
            'A'
        );
        RAISE NOTICE 'Teste 1: Primeira aula criada com sucesso';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Teste 1 falhou: %', SQLERRM;
    END;
    
    -- Teste 2: Criar segunda aula no mesmo horário (deve funcionar)
    BEGIN
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
            'Primeira Aula', 
            sala_id_valido, 
            curso_id_valido2, 
            materia_id_valido, 
            professor_id_valido,
            (CURRENT_DATE + INTERVAL '1 day')::date, 
            2, 
            'A'
        );
        RAISE NOTICE 'Teste 2: Segunda aula criada com sucesso';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Teste 2 falhou: %', SQLERRM;
    END;
    
    -- Teste 3: Tentar criar terceira aula no mesmo horário (deve falhar)
    BEGIN
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
            'Primeira Aula', 
            sala_id_valido, 
            curso_id_valido, 
            materia_id_valido, 
            professor_id_valido,
            (CURRENT_DATE + INTERVAL '1 day')::date, 
            3, 
            'A'
        );
        RAISE NOTICE 'Teste 3: Terceira aula criada (ERRO - não deveria funcionar)';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Teste 3: Falhou corretamente - %', SQLERRM;
    END;
    
    -- Limpar os testes
    DELETE FROM agendamento WHERE dia = (CURRENT_DATE + INTERVAL '1 day')::date AND sala_id = sala_id_valido;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro geral nos testes: %', SQLERRM;
END $$;

-- 7. Verificar se os testes foram executados
SELECT 
    'Resultado dos Testes' as info,
    COUNT(*) as agendamentos_criados,
    'Para o dia de teste' as observacao
FROM agendamento 
WHERE dia = (CURRENT_DATE + INTERVAL '1 day')::date;

-- 8. Mostrar as novas regras implementadas
SELECT 
    'Novas Regras Implementadas' as info,
    'Limite por sala por dia: 12 agendamentos (era 6)' as nova_regra_1,
    'Limite por horário: 2 cursos diferentes (era 1)' as nova_regra_2,
    'Aplicável apenas para aulas (tipo_agendamento = A)' as nova_regra_3,
    'Provas e eventos mantêm regras antigas' as nova_regra_4; 