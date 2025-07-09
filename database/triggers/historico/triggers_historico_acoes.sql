-- Triggers para registrar histórico de ações em todas as tabelas
-- Execute este script no Supabase SQL Editor

-- =====================================================
-- TRIGGERS PARA TABELA SALAS
-- =====================================================

-- Trigger para INSERT na tabela salas
CREATE OR REPLACE FUNCTION registrar_historico_salas_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'INSERT',
        'salas',
        NEW.id,
        NULL,
        jsonb_build_object(
            'id', NEW.id,
            'numero_sala', NEW.numero_sala,
            'qtd_cadeiras', NEW.qtd_cadeiras,
            'disponivel', NEW.disponivel,
            'cor', NEW.cor,
            'projetor', NEW.projetor,
            'tv', NEW.tv,
            'ar_condicionado', NEW.ar_condicionado
        ),
        'Nova sala criada: ' || NEW.numero_sala,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_salas_insert
    AFTER INSERT ON salas
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_salas_insert();

-- Trigger para UPDATE na tabela salas
CREATE OR REPLACE FUNCTION registrar_historico_salas_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'UPDATE',
        'salas',
        NEW.id,
        jsonb_build_object(
            'id', OLD.id,
            'numero_sala', OLD.numero_sala,
            'qtd_cadeiras', OLD.qtd_cadeiras,
            'disponivel', OLD.disponivel,
            'cor', OLD.cor,
            'projetor', OLD.projetor,
            'tv', OLD.tv,
            'ar_condicionado', OLD.ar_condicionado
        ),
        jsonb_build_object(
            'id', NEW.id,
            'numero_sala', NEW.numero_sala,
            'qtd_cadeiras', NEW.qtd_cadeiras,
            'disponivel', NEW.disponivel,
            'cor', NEW.cor,
            'projetor', NEW.projetor,
            'tv', NEW.tv,
            'ar_condicionado', NEW.ar_condicionado
        ),
        'Sala atualizada: ' || NEW.numero_sala,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_salas_update
    AFTER UPDATE ON salas
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_salas_update();

-- Trigger para DELETE na tabela salas
CREATE OR REPLACE FUNCTION registrar_historico_salas_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'DELETE',
        'salas',
        OLD.id,
        jsonb_build_object(
            'id', OLD.id,
            'numero_sala', OLD.numero_sala,
            'qtd_cadeiras', OLD.qtd_cadeiras,
            'disponivel', OLD.disponivel,
            'cor', OLD.cor,
            'projetor', OLD.projetor,
            'tv', OLD.tv,
            'ar_condicionado', OLD.ar_condicionado
        ),
        NULL,
        'Sala excluída: ' || OLD.numero_sala,
        NOW()
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_salas_delete
    AFTER DELETE ON salas
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_salas_delete();

-- =====================================================
-- TRIGGERS PARA TABELA CURSOS
-- =====================================================

-- Trigger para INSERT na tabela cursos
CREATE OR REPLACE FUNCTION registrar_historico_cursos_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'INSERT',
        'cursos',
        NEW.id,
        NULL,
        jsonb_build_object(
            'id', NEW.id,
            'curso', NEW.curso,
            'periodo', NEW.periodo,
            'semestre', NEW.semestre
        ),
        'Novo curso criado: ' || NEW.curso,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cursos_insert
    AFTER INSERT ON cursos
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_cursos_insert();

-- Trigger para UPDATE na tabela cursos
CREATE OR REPLACE FUNCTION registrar_historico_cursos_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'UPDATE',
        'cursos',
        NEW.id,
        jsonb_build_object(
            'id', OLD.id,
            'curso', OLD.curso,
            'periodo', OLD.periodo,
            'semestre', OLD.semestre
        ),
        jsonb_build_object(
            'id', NEW.id,
            'curso', NEW.curso,
            'periodo', NEW.periodo,
            'semestre', NEW.semestre
        ),
        'Curso atualizado: ' || NEW.curso,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cursos_update
    AFTER UPDATE ON cursos
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_cursos_update();

-- Trigger para DELETE na tabela cursos
CREATE OR REPLACE FUNCTION registrar_historico_cursos_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'DELETE',
        'cursos',
        OLD.id,
        jsonb_build_object(
            'id', OLD.id,
            'curso', OLD.curso,
            'periodo', OLD.periodo,
            'semestre', OLD.semestre
        ),
        NULL,
        'Curso excluído: ' || OLD.curso,
        NOW()
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cursos_delete
    AFTER DELETE ON cursos
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_cursos_delete();

-- =====================================================
-- TRIGGERS PARA TABELA PROFESSORES
-- =====================================================

-- Trigger para INSERT na tabela professores
CREATE OR REPLACE FUNCTION registrar_historico_professores_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'INSERT',
        'professores',
        NEW.id,
        NULL,
        jsonb_build_object(
            'id', NEW.id,
            'nome_professor', NEW.nome_professor
        ),
        'Novo professor criado: ' || NEW.nome_professor,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_professores_insert
    AFTER INSERT ON professores
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_professores_insert();

-- Trigger para UPDATE na tabela professores
CREATE OR REPLACE FUNCTION registrar_historico_professores_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'UPDATE',
        'professores',
        NEW.id,
        jsonb_build_object(
            'id', OLD.id,
            'nome_professor', OLD.nome_professor
        ),
        jsonb_build_object(
            'id', NEW.id,
            'nome_professor', NEW.nome_professor
        ),
        'Professor atualizado: ' || NEW.nome_professor,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_professores_update
    AFTER UPDATE ON professores
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_professores_update();

-- Trigger para DELETE na tabela professores
CREATE OR REPLACE FUNCTION registrar_historico_professores_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'DELETE',
        'professores',
        OLD.id,
        jsonb_build_object(
            'id', OLD.id,
            'nome_professor', OLD.nome_professor
        ),
        NULL,
        'Professor excluído: ' || OLD.nome_professor,
        NOW()
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_professores_delete
    AFTER DELETE ON professores
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_professores_delete();

-- =====================================================
-- TRIGGERS PARA TABELA MATERIAS
-- =====================================================

-- Trigger para INSERT na tabela materias
CREATE OR REPLACE FUNCTION registrar_historico_materias_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'INSERT',
        'materias',
        NEW.id,
        NULL,
        jsonb_build_object(
            'id', NEW.id,
            'nome', NEW.nome,
            'curso_id', NEW.curso_id
        ),
        'Nova matéria criada: ' || NEW.nome,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_materias_insert
    AFTER INSERT ON materias
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_materias_insert();

-- Trigger para UPDATE na tabela materias
CREATE OR REPLACE FUNCTION registrar_historico_materias_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'UPDATE',
        'materias',
        NEW.id,
        jsonb_build_object(
            'id', OLD.id,
            'nome', OLD.nome,
            'curso_id', OLD.curso_id
        ),
        jsonb_build_object(
            'id', NEW.id,
            'nome', NEW.nome,
            'curso_id', NEW.curso_id
        ),
        'Matéria atualizada: ' || NEW.nome,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_materias_update
    AFTER UPDATE ON materias
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_materias_update();

-- Trigger para DELETE na tabela materias
CREATE OR REPLACE FUNCTION registrar_historico_materias_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'DELETE',
        'materias',
        OLD.id,
        jsonb_build_object(
            'id', OLD.id,
            'nome', OLD.nome,
            'curso_id', OLD.curso_id
        ),
        NULL,
        'Matéria excluída: ' || OLD.nome,
        NOW()
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_materias_delete
    AFTER DELETE ON materias
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_materias_delete();

-- =====================================================
-- TRIGGERS PARA TABELA AGENDAMENTO (EVENTOS E PROVAS)
-- =====================================================

-- Trigger para INSERT na tabela agendamento
CREATE OR REPLACE FUNCTION registrar_historico_agendamento_insert()
RETURNS TRIGGER AS $$
DECLARE
    tipo_agendamento_texto TEXT;
BEGIN
    -- Determina o tipo de agendamento
    IF NEW.tipo_agendamento = 'E' THEN
        tipo_agendamento_texto := 'Evento';
    ELSIF NEW.tipo_agendamento = 'M' THEN
        tipo_agendamento_texto := 'Prova';
    ELSE
        tipo_agendamento_texto := 'Aula';
    END IF;

    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'INSERT',
        'agendamento',
        NEW.id,
        NULL,
        jsonb_build_object(
            'id', NEW.id,
            'sala_id', NEW.sala_id,
            'curso_id', NEW.curso_id,
            'materia_id', NEW.materia_id,
            'professor_id', NEW.professor_id,
            'dia', NEW.dia,
            'aula_periodo', NEW.aula_periodo,
            'hora_inicio', NEW.hora_inicio,
            'hora_fim', NEW.hora_fim,
            'tipo_agendamento', NEW.tipo_agendamento,
            'nome_evento', NEW.nome_evento,
            'descricao_evento', NEW.descricao_evento
        ),
        'Novo ' || tipo_agendamento_texto || ' agendado para ' || NEW.dia,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_agendamento_insert
    AFTER INSERT ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_agendamento_insert();

-- Trigger para UPDATE na tabela agendamento
CREATE OR REPLACE FUNCTION registrar_historico_agendamento_update()
RETURNS TRIGGER AS $$
DECLARE
    tipo_agendamento_texto TEXT;
BEGIN
    -- Determina o tipo de agendamento
    IF NEW.tipo_agendamento = 'E' THEN
        tipo_agendamento_texto := 'Evento';
    ELSIF NEW.tipo_agendamento = 'M' THEN
        tipo_agendamento_texto := 'Prova';
    ELSE
        tipo_agendamento_texto := 'Aula';
    END IF;

    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'UPDATE',
        'agendamento',
        NEW.id,
        jsonb_build_object(
            'id', OLD.id,
            'sala_id', OLD.sala_id,
            'curso_id', OLD.curso_id,
            'materia_id', OLD.materia_id,
            'professor_id', OLD.professor_id,
            'dia', OLD.dia,
            'aula_periodo', OLD.aula_periodo,
            'hora_inicio', OLD.hora_inicio,
            'hora_fim', OLD.hora_fim,
            'tipo_agendamento', OLD.tipo_agendamento,
            'nome_evento', OLD.nome_evento,
            'descricao_evento', OLD.descricao_evento
        ),
        jsonb_build_object(
            'id', NEW.id,
            'sala_id', NEW.sala_id,
            'curso_id', NEW.curso_id,
            'materia_id', NEW.materia_id,
            'professor_id', NEW.professor_id,
            'dia', NEW.dia,
            'aula_periodo', NEW.aula_periodo,
            'hora_inicio', NEW.hora_inicio,
            'hora_fim', NEW.hora_fim,
            'tipo_agendamento', NEW.tipo_agendamento,
            'nome_evento', NEW.nome_evento,
            'descricao_evento', NEW.descricao_evento
        ),
        tipo_agendamento_texto || ' atualizado para ' || NEW.dia,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_agendamento_update
    AFTER UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_agendamento_update();

-- Trigger para DELETE na tabela agendamento
CREATE OR REPLACE FUNCTION registrar_historico_agendamento_delete()
RETURNS TRIGGER AS $$
DECLARE
    tipo_agendamento_texto TEXT;
BEGIN
    -- Determina o tipo de agendamento
    IF OLD.tipo_agendamento = 'E' THEN
        tipo_agendamento_texto := 'Evento';
    ELSIF OLD.tipo_agendamento = 'M' THEN
        tipo_agendamento_texto := 'Prova';
    ELSE
        tipo_agendamento_texto := 'Aula';
    END IF;

    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'DELETE',
        'agendamento',
        OLD.id,
        jsonb_build_object(
            'id', OLD.id,
            'sala_id', OLD.sala_id,
            'curso_id', OLD.curso_id,
            'materia_id', OLD.materia_id,
            'professor_id', OLD.professor_id,
            'dia', OLD.dia,
            'aula_periodo', OLD.aula_periodo,
            'hora_inicio', OLD.hora_inicio,
            'hora_fim', OLD.hora_fim,
            'tipo_agendamento', OLD.tipo_agendamento,
            'nome_evento', OLD.nome_evento,
            'descricao_evento', OLD.descricao_evento
        ),
        NULL,
        tipo_agendamento_texto || ' excluído de ' || OLD.dia,
        NOW()
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_agendamento_delete
    AFTER DELETE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_agendamento_delete();

-- =====================================================
-- TRIGGERS PARA TABELA PROFESSOR_MATERIAS (ASSOCIAÇÕES)
-- =====================================================

-- Trigger para INSERT na tabela professor_materias
CREATE OR REPLACE FUNCTION registrar_historico_professor_materias_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'INSERT',
        'professor_materias',
        NEW.professor_id,
        NULL,
        jsonb_build_object(
            'professor_id', NEW.professor_id,
            'materia_id', NEW.materia_id
        ),
        'Associação professor-matéria criada',
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_professor_materias_insert
    AFTER INSERT ON professor_materias
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_professor_materias_insert();

-- Trigger para DELETE na tabela professor_materias
CREATE OR REPLACE FUNCTION registrar_historico_professor_materias_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'DELETE',
        'professor_materias',
        OLD.professor_id,
        jsonb_build_object(
            'professor_id', OLD.professor_id,
            'materia_id', OLD.materia_id
        ),
        NULL,
        'Associação professor-matéria removida',
        NOW()
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_professor_materias_delete
    AFTER DELETE ON professor_materias
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_professor_materias_delete();

-- =====================================================
-- VERIFICAÇÃO DOS TRIGGERS CRIADOS
-- =====================================================

-- Comando para verificar se todos os triggers foram criados
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%trigger_%'
ORDER BY event_object_table, event_manipulation; 