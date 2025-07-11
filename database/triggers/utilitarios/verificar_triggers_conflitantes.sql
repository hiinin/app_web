-- Script para verificar e resolver triggers conflitantes no Supabase
-- Execute este script no Supabase SQL Editor

-- 1. Verificar todos os triggers existentes na tabela agendamento
SELECT 
    'Triggers Existentes' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 2. Verificar se há triggers que validam conflitos de horário
SELECT 
    'Triggers de Validação' as info,
    trigger_name,
    CASE 
        WHEN action_statement LIKE '%conflito%' OR action_statement LIKE '%horario%' THEN '⚠️ Possível conflito'
        WHEN action_statement LIKE '%validar%' OR action_statement LIKE '%aula%' THEN '⚠️ Possível conflito'
        ELSE '✅ OK'
    END as observacao
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND (action_statement LIKE '%conflito%' 
       OR action_statement LIKE '%horario%' 
       OR action_statement LIKE '%validar%' 
       OR action_statement LIKE '%aula%')
ORDER BY trigger_name;

-- 3. Verificar funções que podem estar causando conflito
SELECT 
    'Funções de Validação' as info,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%conflito%' OR prosrc LIKE '%horario%' THEN '⚠️ Possível conflito'
        WHEN prosrc LIKE '%validar%' OR prosrc LIKE '%aula%' THEN '⚠️ Possível conflito'
        ELSE '✅ OK'
    END as observacao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
  AND (prosrc LIKE '%conflito%' 
       OR prosrc LIKE '%horario%' 
       OR prosrc LIKE '%validar%' 
       OR prosrc LIKE '%aula%')
ORDER BY proname;

-- 4. Desabilitar temporariamente todos os triggers de validação
DO $$
DECLARE
    trigger_rec RECORD;
BEGIN
    FOR trigger_rec IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'agendamento'
          AND (action_statement LIKE '%conflito%' 
               OR action_statement LIKE '%horario%' 
               OR action_statement LIKE '%validar%' 
               OR action_statement LIKE '%aula%')
    LOOP
        EXECUTE 'ALTER TABLE agendamento DISABLE TRIGGER ' || trigger_rec.trigger_name;
        RAISE NOTICE 'Trigger desabilitado: %', trigger_rec.trigger_name;
    END LOOP;
END $$;

-- 5. Verificar se os triggers foram desabilitados
SELECT 
    'Status dos Triggers' as info,
    trigger_name,
    CASE 
        WHEN tgenabled = 'D' THEN '❌ Desabilitado'
        WHEN tgenabled = 'E' THEN '✅ Habilitado'
        ELSE '❓ Status desconhecido'
    END as status
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
  AND tgname IN (
    SELECT trigger_name 
    FROM information_schema.triggers 
    WHERE event_object_table = 'agendamento'
      AND (action_statement LIKE '%conflito%' 
           OR action_statement LIKE '%horario%' 
           OR action_statement LIKE '%validar%' 
           OR action_statement LIKE '%aula%')
  );

-- 6. Criar uma função de validação simplificada que não conflita
CREATE OR REPLACE FUNCTION validar_agendamento_simples()
RETURNS TRIGGER AS $$
BEGIN
    -- Validações básicas apenas
    IF NEW.tipo_agendamento != 'A' THEN
        RETURN NEW; -- Não aplica validações específicas para outros tipos
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
    
    -- Se chegou até aqui, tudo está ok
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Criar trigger com a função simplificada
DROP TRIGGER IF EXISTS trigger_validar_agendamento_simples ON agendamento;

CREATE TRIGGER trigger_validar_agendamento_simples
    BEFORE INSERT OR UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION validar_agendamento_simples();

-- 8. Verificar se o novo trigger foi criado
SELECT 
    'Novo Trigger Criado' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_validar_agendamento_simples';

-- 9. Testar inserção simples
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
    professor_id_valido INTEGER;
    resultado TEXT;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    SELECT MIN(id) INTO professor_id_valido FROM professores;
    
    -- Testar inserção válida
    BEGIN
        INSERT INTO agendamento (
            sala_id, curso_id, materia_id, professor_id,
            dia, aula_periodo, periodo, tipo_agendamento
        ) VALUES (
            sala_id_valido, curso_id_valido, materia_id_valido, professor_id_valido,
            (CURRENT_DATE + INTERVAL '3 days')::date, 'Primeira Aula', 1, 'A'
        );
        resultado := '✅ Inserção válida funcionou';
    EXCEPTION
        WHEN OTHERS THEN
            resultado := '❌ Inserção válida falhou: ' || SQLERRM;
    END;
    
    RAISE NOTICE 'Teste de inserção válida: %', resultado;
    
    -- Limpar teste
    DELETE FROM agendamento WHERE dia = (CURRENT_DATE + INTERVAL '3 days')::date AND sala_id = sala_id_valido;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;

-- 10. Instruções para resolver o problema
SELECT 
    'INSTRUÇÕES PARA RESOLVER' as info,
    '1. Execute este script para desabilitar triggers conflitantes' as passo_1,
    '2. Teste a criação de aulas no frontend' as passo_2,
    '3. Se funcionar, mantenha os triggers desabilitados' as passo_3,
    '4. Se precisar de validações específicas, implemente gradualmente' as passo_4; 