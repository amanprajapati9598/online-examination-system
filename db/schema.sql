CREATE DATABASE IF NOT EXISTS smartexam_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE smartexam_db;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS cheating_logs;
DROP TABLE IF EXISTS student_answers;
DROP TABLE IF EXISTS student_exams;
DROP TABLE IF EXISTS question_options;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS exams;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS system_settings;
DROP TABLE IF EXISTS users;

-- 1. Users Table (Role-based: admin, teacher, student)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'teacher', 'student') NOT NULL,
    profile_image VARCHAR(255) NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB;

-- 2. Courses Table
CREATE TABLE courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3. Subjects Table (Mapped to Courses)
CREATE TABLE subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    INDEX idx_course (course_id)
) ENGINE=InnoDB;

-- 4. Exams Table
CREATE TABLE exams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description TEXT NULL,
    subject_id INT NOT NULL,
    teacher_id INT NOT NULL,
    duration_minutes INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    total_marks DECIMAL(6, 2) NOT NULL,
    passing_marks DECIMAL(6, 2) NOT NULL,
    negative_marking_factor DECIMAL(3, 2) DEFAULT 0.00,
    randomize_questions TINYINT(1) DEFAULT 0,
    randomize_options TINYINT(1) DEFAULT 0,
    anti_cheating_enabled TINYINT(1) DEFAULT 1,
    is_published TINYINT(1) DEFAULT 0,
    qr_code_token VARCHAR(255) NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_subject (subject_id),
    INDEX idx_teacher (teacher_id),
    INDEX idx_published (is_published)
) ENGINE=InnoDB;

-- 5. Questions Table
CREATE TABLE questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    question_text TEXT NOT NULL,
    question_type ENUM('mcq', 'tf') DEFAULT 'mcq',
    marks DECIMAL(4, 2) DEFAULT 1.00,
    negative_marks DECIMAL(4, 2) DEFAULT 0.00,
    attachment_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
    INDEX idx_exam (exam_id)
) ENGINE=InnoDB;

-- 6. Question Options Table (For MCQs and True/False options)
CREATE TABLE question_options (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    option_text TEXT NOT NULL,
    is_correct TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question (question_id)
) ENGINE=InnoDB;

-- 7. Student Exams Sessions Table (Tracks exam attempts)
CREATE TABLE student_exams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    status ENUM('registered', 'ongoing', 'submitted', 'abandoned') DEFAULT 'registered',
    start_time DATETIME NULL,
    submit_time DATETIME NULL,
    score DECIMAL(6, 2) DEFAULT 0.00,
    tab_switches_count INT DEFAULT 0,
    fullscreen_exits_count INT DEFAULT 0,
    auto_submitted TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
    UNIQUE KEY uniq_student_exam (student_id, exam_id),
    INDEX idx_student (student_id),
    INDEX idx_exam_attempt (exam_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- 8. Student Answers Table
CREATE TABLE student_answers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_exam_id INT NOT NULL,
    question_id INT NOT NULL,
    selected_option_id INT NULL,
    answer_text TEXT NULL,
    is_correct TINYINT(1) DEFAULT 0,
    marks_obtained DECIMAL(5, 2) DEFAULT 0.00,
    saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_exam_id) REFERENCES student_exams(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY uniq_attempt_question (student_exam_id, question_id),
    INDEX idx_attempt (student_exam_id),
    INDEX idx_question_ans (question_id)
) ENGINE=InnoDB;

-- 9. Cheating Logs Table (Logs active anti-cheating events)
CREATE TABLE cheating_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_exam_id INT NOT NULL,
    event_type ENUM('tab_switch', 'fullscreen_exit', 'browser_refresh', 'other') NOT NULL,
    details TEXT NULL,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_exam_id) REFERENCES student_exams(id) ON DELETE CASCADE,
    INDEX idx_student_exam_log (student_exam_id)
) ENGINE=InnoDB;

-- 10. Notifications Table
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_notif (user_id),
    INDEX idx_read (is_read)
) ENGINE=InnoDB;

-- 11. System Settings Table
CREATE TABLE system_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value TEXT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Seed system settings
INSERT INTO system_settings (setting_key, setting_value) VALUES 
('system_name', 'SmartExam'),
('allow_registration', 'true'),
('theme_mode', 'light');

-- Seed initial users
-- admin123 -> $2y$10$xiNQHKQRk1HCVADVUT6DjuB3SQWaCP/v90xmUuL2Gcn0JeeKr1.QS
-- teacher123 -> $2y$10$i8m776eox8V8MFKiA83CeudKBj9aOqqNhcctBnc.dmXr6KlrpuVMe
-- student123 -> $2y$10$wkolSajXkzR8scl9F4VquOz1Nv/OoEgg.7jxMVkhXtgu77UDcLBdm
INSERT INTO users (name, email, password, role, status) VALUES
('System Administrator', 'admin@smartexam.com', '$2y$10$xiNQHKQRk1HCVADVUT6DjuB3SQWaCP/v90xmUuL2Gcn0JeeKr1.QS', 'admin', 'active'),
('Professor Alan Smith', 'teacher@smartexam.com', '$2y$10$i8m776eox8V8MFKiA83CeudKBj9aOqqNhcctBnc.dmXr6KlrpuVMe', 'teacher', 'active'),
('John Doe', 'student@smartexam.com', '$2y$10$wkolSajXkzR8scl9F4VquOz1Nv/OoEgg.7jxMVkhXtgu77UDcLBdm', 'student', 'active');

-- Seed initial courses & subjects
INSERT INTO courses (name, code, description) VALUES
('Computer Science Engineering', 'CSE', 'Bachelor of Technology in Computer Science');

INSERT INTO subjects (course_id, name, code, description) VALUES
(1, 'Database Management Systems', 'CSE-301', 'Introductory course to relational database management systems and SQL.');
