# 🎓 Sistema de Gestão de Salas e Cursos

Este é um projeto web feito em **Flutter e Dart** com backend no **Supabase**, que permite a criação, edição e visualização de **salas** e **cursos**, vinculado a um sistema onde **alunos** podem se cadastrar, selecionar seu curso, período e semestre, e visualizar a **sala correta** onde devem estar.

## 📌 Funcionalidades

### 🔐 Área do Administrador (via Web)
- Login com credenciais (login e senha)
- CRUD de **salas**
- CRUD de **cursos**
- Associação de **salas aos cursos** por período e semestre

### 📱 Aplicativo Mobile para Alunos
- Cadastro de conta
- Escolha do **curso**, **período** e **semestre**
- Visualização da **sala correspondente**
- Experiência simples e direta

## 🧱 Tecnologias Utilizadas

- **Flutter + Dart** (Web & Mobile)
- **Supabase** (Banco de dados PostgreSQL + autenticação)
- **Supabase Auth** (para alunos)
- **Supabase Tables** (para gerenciamento de cursos e salas)
- **bcrypt** (criptografia de senhas de admin)
- **RLS (Row Level Security)** para segurança no Supabase

## 📂 Estrutura do Banco de Dados

### Tabela `admins`
| Campo      | Tipo     | Detalhes               |
|------------|----------|------------------------|
| id         | UUID     | Chave primária         |
| login      | TEXT     | Único                  |
| password   | TEXT     | Senha criptografada    |
| created_at | TIMESTAMP| Criado automaticamente |

### Tabela `cursos`
| Campo      | Tipo     | Detalhes          |
|------------|----------|-------------------|
| id         | UUID     | Chave primária    |
| nome       | TEXT     | Nome do curso     |
| created_at | TIMESTAMP| Data de criação   |

### Tabela `salas`
| Campo      | Tipo     | Detalhes               |
|------------|----------|------------------------|
| id         | UUID     | Chave primária         |
| nome       | TEXT     | Identificação da sala  |
| created_at | TIMESTAMP| Data de criação        |

### Tabela `curso_salas`
| Campo        | Tipo     | Detalhes                          |
|--------------|----------|-----------------------------------|
| id           | UUID     | Chave primária                    |
| curso_id     | UUID     | FK para `cursos`                  |
| sala_id      | UUID     | FK para `salas`                   |
| periodo      | TEXT     | Ex: "Matutino", "Noturno"         |
| semestre     | INT      | Semestre (ex: 1, 2, 3, etc.)       |
| created_at   | TIMESTAMP| Data de criação                   |

## 🚀 Como Executar

### Requisitos
- Flutter SDK
- Conta no Supabase
- `.env` com a URL e chave do Supabase

### Passos

1. Clone o repositório:
   ```bash
   git clone https://github.com/hiinin/app_web.git
   cd nome-do-repo
   
2. Instale as dependências:
   flutter pub get

3.Configure o Supabase e adicione as chaves ao seu arquivo .env.

4.Rode o projeto web:
   flutter run -d chrome

