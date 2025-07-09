-- Adicionar coluna tipo_usuario na tabela users
-- Execute este script no Supabase SQL Editor

-- 1. Adicionar a coluna tipo_usuario
ALTER TABLE public.users 
ADD COLUMN tipo_usuario text DEFAULT 'aluno' CHECK (tipo_usuario IN ('aluno', 'professor'));

-- 2. Atualizar todos os usuários existentes para 'aluno'
UPDATE public.users SET tipo_usuario = 'aluno' WHERE tipo_usuario IS NULL;

-- 3. Verificar se foi aplicado corretamente
SELECT 
    id,
    email,
    nome,
    tipo_usuario,
    created_at
FROM public.users 
ORDER BY created_at DESC; 