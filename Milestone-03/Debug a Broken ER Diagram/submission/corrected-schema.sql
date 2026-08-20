-- TaskSphere corrected relational schema
-- PostgreSQL 14+
-- The design separates stable identifiers from display attributes, enforces
-- referential integrity, and models project membership as a many-to-many
-- relationship through project_members.

BEGIN;

CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(320) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_name_not_blank CHECK (btrim(name) <> ''),
    CONSTRAINT users_email_not_blank CHECK (btrim(email) <> '')
);

CREATE TABLE projects (
    project_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_name VARCHAR(150) NOT NULL,
    owner_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT projects_name_not_blank CHECK (btrim(project_name) <> ''),
    CONSTRAINT projects_owner_fk
        FOREIGN KEY (owner_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT projects_owner_name_unique UNIQUE (owner_id, project_name)
);

CREATE TABLE tasks (
    task_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id BIGINT NOT NULL,
    task_name VARCHAR(200) NOT NULL,
    description TEXT,
    assigned_user_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'todo',
    due_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tasks_name_not_blank CHECK (btrim(task_name) <> ''),
    CONSTRAINT tasks_status_valid CHECK (status IN ('todo', 'in_progress', 'blocked', 'done')),
    CONSTRAINT tasks_project_fk
        FOREIGN KEY (project_id)
        REFERENCES projects (project_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT tasks_assigned_user_fk
        FOREIGN KEY (assigned_user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE project_members (
    project_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, user_id),
    CONSTRAINT project_members_role_valid CHECK (role IN ('member', 'manager')),
    CONSTRAINT project_members_project_fk
        FOREIGN KEY (project_id)
        REFERENCES projects (project_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT project_members_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Foreign-key indexes support common joins and filtering as the data grows.
CREATE INDEX idx_projects_owner_id ON projects (owner_id);
CREATE INDEX idx_tasks_project_id ON tasks (project_id);
CREATE INDEX idx_tasks_assigned_user_id ON tasks (assigned_user_id);
CREATE INDEX idx_tasks_project_status ON tasks (project_id, status);
CREATE INDEX idx_project_members_user_id ON project_members (user_id);

COMMIT;
