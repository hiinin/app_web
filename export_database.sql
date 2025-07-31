-- Script para exportar o banco de dados do Supabase
-- Execute este script no SQL Editor do Supabase para gerar os comandos de exportação

-- 1. Exportar estrutura das tabelas
SELECT 
    '-- Estrutura da tabela: ' || table_name as comentario,
    'CREATE TABLE ' || table_name || ' (' ||
    string_agg(
        column_name || ' ' || data_type || 
        CASE 
            WHEN character_maximum_length IS NOT NULL 
            THEN '(' || character_maximum_length || ')'
            ELSE ''
        END ||
        CASE 
            WHEN is_nullable = 'NO' THEN ' NOT NULL'
            ELSE ''
        END ||
        CASE 
            WHEN column_default IS NOT NULL 
            THEN ' DEFAULT ' || column_default
            ELSE ''
        END,
        ', '
        ORDER BY ordinal_position
    ) || ');' as create_table
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name NOT LIKE 'pg_%'
  AND table_name NOT LIKE 'information_schema%'
GROUP BY table_name
ORDER BY table_name;

-- 2. Exportar dados das tabelas principais
-- Tabela admin
SELECT '-- Dados da tabela admin' as comentario;
SELECT 'INSERT INTO admin (id, login, password, created_at) VALUES (' ||
       '''' || id || ''', ' ||
       '''' || login || ''', ' ||
       '''' || password || ''', ' ||
       '''' || created_at || ''');' as insert_admin
FROM admin;

-- Tabela cursos
SELECT '-- Dados da tabela cursos' as comentario;
SELECT 'INSERT INTO cursos (id, curso, semestre, periodo, created_at) VALUES (' ||
       '''' || id || ''', ' ||
       '''' || curso || ''', ' ||
       '''' || semestre || ''', ' ||
       COALESCE(periodo::text, 'NULL') || ', ' ||
       '''' || created_at || ''');' as insert_cursos
FROM cursos;

-- Tabela salas
SELECT '-- Dados da tabela salas' as comentario;
SELECT 'INSERT INTO salas (id, numero_sala, qtd_cadeiras, disponivel, cor, projetor, tv, ar_condicionado, created_at) VALUES (' ||
       '''' || id || ''', ' ||
       '''' || numero_sala || ''', ' ||
       qtd_cadeiras || ', ' ||
       disponivel || ', ' ||
       '''' || COALESCE(cor, '') || ''', ' ||
       COALESCE(projetor::text, 'NULL') || ', ' ||
       COALESCE(tv::text, 'NULL') || ', ' ||
       COALESCE(ar_condicionado::text, 'NULL') || ', ' ||
       '''' || created_at || ''');' as insert_salas
FROM salas;

-- Tabela materias
SELECT '-- Dados da tabela materias' as comentario;
SELECT 'INSERT INTO materias (id, nome, curso_id, created_at) VALUES (' ||
       '''' || id || ''', ' ||
       '''' || nome || ''', ' ||
       curso_id || ', ' ||
       '''' || created_at || ''');' as insert_materias
FROM materias;

-- Tabela professores
SELECT '-- Dados da tabela professores' as comentario;
SELECT 'INSERT INTO professores (id, nome_professor, created_at) VALUES (' ||
       '''' || id || ''', ' ||
       '''' || nome_professor || ''', ' ||
       '''' || created_at || ''');' as insert_professores
FROM professores;

-- Tabela professor_materias
SELECT '-- Dados da tabela professor_materias' as comentario;
SELECT 'INSERT INTO professor_materias (id, professor_id, materia_id, created_at) VALUES (' ||
       '''' || id || ''', ' ||
       professor_id || ', ' ||
       materia_id || ', ' ||
       '''' || created_at || ''');' as insert_professor_materias
FROM professor_materias;

-- Tabela agendamento
SELECT '-- Dados da tabela agendamento' as comentario;
SELECT 'INSERT INTO agendamento (id, dia, aula_periodo, hora_inicio, hora_fim, tipo_agendamento, nome_evento, descricao_evento, curso_id, sala_id, materia_id, professor_id, created_at) VALUES (' ||
       '''' || id || ''', ' ||
       '''' || dia || ''', ' ||
       '''' || aula_periodo || ''', ' ||
       '''' || hora_inicio || ''', ' ||
       '''' || hora_fim || ''', ' ||
       '''' || tipo_agendamento || ''', ' ||
       '''' || COALESCE(nome_evento, '') || ''', ' ||
       '''' || COALESCE(descricao_evento, '') || ''', ' ||
       COALESCE(curso_id::text, 'NULL') || ', ' ||
       COALESCE(sala_id::text, 'NULL') || ', ' ||
       COALESCE(materia_id::text, 'NULL') || ', ' ||
       COALESCE(professor_id::text, 'NULL') || ', ' ||
       '''' || created_at || ''');' as insert_agendamento
FROM agendamento;

-- Tabela users
SELECT '-- Dados da tabela users' as comentario;
SELECT 'INSERT INTO users (id, email, nome, curso_id, semestre, periodo, tipo_usuario, created_at) VALUES (' ||
       '''' || id || ''', ' ||
       '''' || email || ''', ' ||
       '''' || nome || ''', ' ||
       COALESCE(curso_id::text, 'NULL') || ', ' ||
       '''' || COALESCE(semestre, '') || ''', ' ||
       '''' || COALESCE(periodo, '') || ''', ' ||
       '''' || COALESCE(tipo_usuario, 'aluno') || ''', ' ||
       '''' || created_at || ''');' as insert_users
FROM users;

-- Tabela historico_acoes
SELECT '-- Dados da tabela historico_acoes' as comentario;
SELECT 'INSERT INTO historico_acoes (id, acao, tabela, dados_anteriores, dados_novos, data_hora, usuario_id) VALUES (' ||
       '''' || id || ''', ' ||
       '''' || acao || ''', ' ||
       '''' || tabela || ''', ' ||
       '''' || COALESCE(dados_anteriores::text, '') || ''', ' ||
       '''' || COALESCE(dados_novos::text, '') || ''', ' ||
       '''' || data_hora || ''', ' ||
       COALESCE(usuario_id::text, 'NULL') || ');' as insert_historico
FROM historico_acoes;

-- 3. Exportar funções personalizadas
SELECT '-- Funções personalizadas' as comentario;
SELECT 'CREATE OR REPLACE FUNCTION ' || proname || '(' || 
       pg_get_function_arguments(oid) || ') RETURNS ' || 
       pg_get_function_result(oid) || ' AS $$' || 
       prosrc || '$$ LANGUAGE ' || lanname || ';' as create_function
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_language l ON p.prolang = l.oid
WHERE n.nspname = 'public'
  AND (prosrc LIKE '%agendamento%' 
       OR prosrc LIKE '%historico%' 
       OR prosrc LIKE '%validar%'
       OR prosrc LIKE '%definir_horarios%');

-- 4. Exportar triggers
SELECT '-- Triggers' as comentario;
SELECT 'CREATE TRIGGER ' || trigger_name || 
       ' ' || action_timing || ' ' || event_manipulation || 
       ' ON ' || event_object_table || 
       ' FOR EACH ' || action_orientation || 
       ' EXECUTE FUNCTION ' || 
       SUBSTRING(action_statement FROM 'EXECUTE FUNCTION ([^(]+)') || '();' as create_trigger
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
  AND event_object_table IN ('agendamento', 'historico_acoes', 'professores', 'materias', 'cursos', 'salas');

-- 5. Exportar políticas RLS (Row Level Security)
SELECT '-- Políticas RLS' as comentario;
SELECT 'CREATE POLICY "' || policyname || '" ON ' || tablename || 
       ' FOR ' || permissive || ' ' || cmd || 
       ' USING (' || qual || ');' as create_policy
FROM pg_policies 
WHERE schemaname = 'public';

-- 6. Habilitar RLS nas tabelas
SELECT '-- Habilitar RLS' as comentario;
SELECT 'ALTER TABLE ' || table_name || ' ENABLE ROW LEVEL SECURITY;' as enable_rls
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name NOT LIKE 'pg_%'
  AND table_name NOT LIKE 'information_schema%';